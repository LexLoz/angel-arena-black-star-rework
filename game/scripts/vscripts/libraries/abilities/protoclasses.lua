--[[
	Protoclasses.

	Any object has a hidden __class__ property that is
	a reference to the class that this object belongs to.
	An object whose __class__ property points to itself is a class.
	Classes can be instantiated by calling the class object (e. g. obj = SomeClass()).
	Calling a class object results in its __call metamethod being invoked,
	which in turn just instantiates a new object using create() method.

	Objects can clone themselves using create() method. Its main goal is to
	create an object that belongs to the same class, but also delegates its
	properties to the parent object - prototype - if there's one.
	Class objects usually do not have any prototypes. Thus invoking create()
	on a class object just instantiates a new object that belongs to this class,
	but does not have any prototypes. That is, the object is a firstborn instance of a class.
	However, it's possible to create a new class using prototype as its base class.
	But I clearly don't see any reason to do so...

	Protoclasses implement sharing and delegation using Lua metatables.
	Every object has its own metatable with __index property pointing
	either to its class or prototype object. Hence we get the inheritance tree.
	There are 3 important functions to access object's class, base class,
	and to check whether the object is an instance of some other class.
	Those functions rely on the class' implementation details of __getclass__,
	__getbase__ and __instanceof__ hidden properties.
	While __getbase__ and __instanceof__ properties are kind of easy to
	understand, the __getclass__ property is something that should be explained.

	Initially, Valve's version of getclass() function works as following:
	1. rawget() the __index property of object's metatable, if any.
	2. rawget() the __getclass__ property of the __index property value.
	3. If there's one, call __getclass__ with object as an argument.
	4. __getclass__ checks if the object's metatable __index property is a class.
	5. If it is, then return is. Otherwise, return nil.

	Our version just uses the hidden __class__ property. Otherwise,
	it would be too heavy to call getclass() on an object with
	tall inheritance tree (N^2 complexity vs N).

	May be overridden by class object for the desired behaviour.
]]
local function __getclass__(obj)
	if isclass(obj.__class__) then
		return obj.__class__
	end
	return nil
end

local function __getbase__(cls)
	if isclass(cls) then
		return cls.__base__
	end
	return nil
end

local function __instanceof__(obj, class)
	local objclass = getclass(obj)
	while objclass do
		if objclass == class then
			return true
		end
		objclass = objclass.__base__
	end
	return false
end

function Class(members, static, base)
	local c = {__props__ = {}, __base__ = base}
	c.__class__ = c
	if static ~= nil then
		for k, v in pairs(static) do
			c[k] = v
		end
	end
	if base ~= nil then
		for k, v in pairs(base.__props__) do
			if type(v) ~= "function" then
				c.__props__[k] = v
			else
				c[k] = v
			end
		end
	end
	if members ~= nil then
		for k, v in pairs(members) do
			if type(v) ~= "function" then
				c.__props__[k] = v
			else
				c[k] = v
			end
		end
	end
	c.__getclass__ = __getclass__
	c.__getbase__ = __getbase__
	c.__instanceof__ = __instanceof__
	c.create = function(obj, ...)
		local instance = {}
		for k, v in pairs(c.__props__) do
			instance[k] = deepcopy(v)
		end
		setmetatable(instance, {__index = obj})
		if instance.constructor ~= nil then
			instance:constructor(...)
		end
		return instance
	end
	setmetatable(c, {
		__index = base,
		__call = c.create -- be wary though that the __call metamethod does not work for derived objects, the idea is to use obj:create() explicitly
	})
	return c
end

function isclass(obj)
	return obj and obj.__class__ == obj or false
end

function getclass(obj)
	if isclass(obj) then
		return obj
	end
	local cls = obj.__getclass__
	return cls and cls(obj)
end

function getbase(obj)
	if isclass(obj) then
		local cls = rawget(obj, "__getbase__")
		return cls and cls(obj)
	end
	local cls = getclass(obj)
	if cls then
		cls = rawget(cls, "__getbase__")
		return cls and cls(obj)
	end
	return nil
end

function instanceof(obj, class)
end

function bind(f, ...)
	local args = {...}
	return function(...)
		return f(unpack(args), ...)
	end
end

function proxy(target, traps)
	local mt -- mind that "t" argument points to the proxy table
	local target_type = type(target)
	local transparent_mt = {
		__index = target,
		__newindex = target,
		__call = function(t, ...)
			return target(...)
		end
	}

	if traps ~= nil then
		mt = {}
		traps = shallowcopy(traps)
		if target_type == "table" then
			if traps.index ~= nil then
				mt.__index = function(t, k)
					return traps.index(target, k)
				end
			else
				mt.__index = transparent_mt.__index
			end
			if traps.newindex ~= nil then
				mt.__newindex = function(t, k, v)
					traps.newindex(target, k, v)
				end
			else
				mt.__newindex = transparent_mt.__newindex
			end
			if traps.call ~= nil then
				mt.__call = function(t, ...)
					return traps.call(target, ...)
				end
			else
				-- bind() works incorrectly here, fix it
				mt.__call = transparent_mt.__call
			end
		else
			error("Only table proxies are implemented now")
		end
	else
		mt = transparent_mt
	end
	return setmetatable({}, mt)
end

--[[
-- This is a tough one
function proxify(target, traps)
	local mt = getmetatable(target)

	if mt == nil then
		mt = {}
	end
	return target
end
]]

function Static_Wrap(t, key)
	assert(t[key] ~= nil)
	return function(...)
		if not t[key] then
			error("Static_Wrap("..tostring(t)..", "..tostring(key)..") yields invalid value")
		end
		return t[key](...)
	end
end

function Poly_Wrap(t, key)
	assert(t[key] ~= nil)
	return function(...)
		return t[key](t, ...)
	end
end

function HasUserdataInstance(v)
	return type(v.__self) == "userdata"
end