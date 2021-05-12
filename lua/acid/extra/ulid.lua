-- luacheck: globals vim
---
-- Module for creating Universally Unique Lexicographically Sortable Identifiers.
--
-- Modeled after the [ulid implementation by alizain](https://github.com/alizain/ulid). Please checkout the
-- documentation there for the design and characteristics of ulid.
--
-- **IMPORTANT**: the standard Lua versions, based on the standard C library are
-- unfortunately very weak regarding time functions and randomizers.
-- So make sure to set it up properly!
--
--see https://github.com/Tieske/ulid.lua
--copyright Copyright 2016-2017 Thijs Schreijer
--license [mit](https://opensource.org/licenses/MIT)
--author Thijs Schreijer


-- Crockford's Base32 https://en.wikipedia.org/wiki/Base32
local ENCODING = {
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
  "A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M",
  "N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z"
}
local ENCODING_LEN = #ENCODING
local TIME_LEN = 10
local RANDOM_LEN = 16

local floor = math.floor
local concat = table.concat
local random = math.random
local now

if package.loaded["socket"] and package.loaded["socket"].gettime then
  -- LuaSocket
  now = package.loaded["socket"].gettime
else
  now = function() return vim.api.nvim_call_function("localtime", {}) end
end

math.randomseed(now())

--- generates the time-based part of a `ulid`.
-- @param[opt] time time to generate the string from, in seconds since
-- unix epoch, with millisecond precision (defaults to now)
-- @param[opt] len the length of the time-based string to return (defaults to 10)
-- @return time-based part of `ulid` string
local function encode_time(time, len)
  time = floor((time or now()) * 1000)
  len = len or TIME_LEN

  local result = {}
  for i = len, 1, -1 do
    local mod = time % ENCODING_LEN
    result[i] = ENCODING[mod + 1]
    time = (time - mod) / ENCODING_LEN
  end
  return concat(result)
end

--- generates the random part of a `ulid`.
-- @param[opt] len the length of the random string to return (defaults to 16)
-- @return random part of `ulid` string
local function encode_random(len)
  len = len or RANDOM_LEN
  local result = {}
  for i = 1, len do
    result[i] = ENCODING[floor(random() * ENCODING_LEN) + 1]
  end
  return concat(result)
end

local function ulid(time)
  return encode_time(time) .. encode_random()
end

local _M = {
    ulid = ulid,
    encode_time = encode_time,
    encode_random = encode_random,
  }

return setmetatable(_M, {
    __call = function(_, ...)
      return ulid(...)
    end
  })
