-- Common utilities

--[[

  prepare(db, query, ...)

A PreparedStatement-like query execution helper for luasql-postgres.
Automatically quotes and escapes strings passed as arguments. Parameters are
denoted with the question-mark character ('?').

Reports count mismatches in SQL query parameters and function args and provides
pretty good debugging context.

Acceptable arguments are of types: string, nil, number.

Example usage:
   prepare(db, "INSERT INTO tab VALUES (?, ?)", "Fred", 22)

Doesn't support ? characters embedded in strings in query. Use:
   prepare(db, "INSERT INTO tab2 VALUES (?)", "lol?")

--]]
function pmutils.prepare(db, query, ...)
   local join_table = {}
   local argc = select('#', ...)

   local escaped
   local val
   local valtype

   local fin = false
   local i = 0
   for split_query in string.gmatch(query, "[^%?]+") do
      if fin then
         error("prepare(): Too few function arguments (context: \""
                  .. table.concat(join_table) .. "\")", 3)
      end

      i = i + 1
      table.insert(join_table, split_query)

      if i > argc then
         fin = true
      else
         val = select(i, ...)
         valtype = type(val)

         if valtype == "string" then
            escaped = "'" .. db:escape(val) .. "'"
         elseif valtype == "number" then
            escaped = db:escape(tostring(val))
         elseif valtype == "nil" then
            escaped = "NULL"
         else
            error("prepare(): Arg " .. tostring(i)
                     .. " is not of type: string, number, nil (context: \""
                     .. table.concat(join_table) .. "\")")
         end

         table.insert(join_table, escaped)
      end
   end
   if i ~= (argc + 1) then
      error("prepare(): Arg count doesn't equal SQL parameter count (context: \""
               .. table.concat(join_table) .. "\")")
   end
   return db:execute(table.concat(join_table))
end


-- Used for retrieving the keys and values of a table,
-- Returns two lists
function pmutils.table_keyvals(tab)
   local keyset = {}
   local valset = {}
   local n = 0
   for k, v in pairs(tab) do
      n = n + 1
      keyset[n] = k
      valset[n] = v
   end
   return keyset, valset
end


-- Search for an element in a table
function pmutils.search(element, tab)
   for _, v in ipairs(tab) do
      if v == element then
         return true
      end
   end
   return false
end

-- Stringifies a vector V, frequently used as a table key
--[[ USE dump(tab) TO STRINGIFY A TABLE ]]--
function ptos(x, y, z)
   return tostring(x) .. ", " .. tostring(y) .. ", " .. tostring(z)
end

function vtos(v)
   return tostring(v.x) .. ", " .. tostring(v.y) .. ", " .. tostring(v.z)
end
