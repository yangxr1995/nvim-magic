local M = {}

local fs = require('nvim-magic.fs')
local log = require('nvim-magic.log')

local TemplateMethods = {}

-- TODO: replace with an actual mustache implementation e.g. lustache - this only (probably) works for simple tags
function TemplateMethods:fill(values)
	local filled = self.template

	-- a real mustache implementation won't have this issue of having to check for strings
	-- which might get accidentally substituted
	local substs = {}
	for k, _ in pairs(values) do
		table.insert(substs, '{{' .. tostring(k) .. '}}')
	end
	for _, s in pairs(substs) do
		for k, v in pairs(values) do
			if v:find(s) ~= nil then
				error('found ' .. s .. " in '" .. k .. "' value, cannot continue for this template")
			end
		end
	end

	for k, v in pairs(values) do
		local subst = '{{' .. tostring(k) .. '}}'
		filled = filled:gsub(subst, v, 1)
	end
	return filled
end

local TemplateMt = { __index = TemplateMethods }

function M.new(tmpl, stop_code)
	local template = {
		template = tmpl,
		-- TODO: parse tags as well
		stop_code = stop_code,
	}
	return setmetatable(template, TemplateMt)
end

local function load(name)
	local prompt_dir = 'prompts/' .. name

	local tmpl = fs.read(vim.api.nvim_get_runtime_file(prompt_dir .. '/template.mustache', false)[1])
	local meta_raw = fs.read(vim.api.nvim_get_runtime_file(prompt_dir .. '/meta.json', false)[1])
	local meta = vim.fn.json_decode(meta_raw)

	return M.new(tmpl, meta.stop_code)
end

M.loaded = {}
for _, name in pairs({ 'alter', 'docstring' }) do
	M.loaded[name] = load(name)
	log.fmt_debug('Loaded template=%s', name)
end

return M