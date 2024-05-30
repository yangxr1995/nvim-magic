local openai = {}

local backend = require('nvim-magic-openai.backend')
local cache = require('nvim-magic-openai._cache')
local log = require('nvim-magic-openai._log')
local http = require('nvim-magic-openai._http')

local DEFAULT_API_ENDPOINT = 'https://api.deepseek.com/chat/completions'
local DEFAULT_MODEL = 'deepseek-coder'
local API_KEY_ENVVAR = 'OPENAI_API_KEY'

local function env_get_api_key()
	local api_key = vim.env[API_KEY_ENVVAR]
	assert(api_key ~= nil and api_key ~= '', API_KEY_ENVVAR .. ' must be set in your environment')
	return api_key
end

local function default_config()
	return {
		api_endpoint = DEFAULT_API_ENDPOINT,
		cache = {
			dir_name = 'http',
		},
		model = DEFAULT_MODEL
	}
end

function openai.version()
	return '0.3.2-dev'
end

function openai.new(override)
	local config = default_config()

	if override then
		assert(type(override) == 'table', 'config must be a table')

		if override.api_endpoint then
			assert(
				type(override.api_endpoint) == 'string' and 1 <= #override.api_endpoint,
				'api_endpoint must be a non-empty string'
			)
			config.api_endpoint = override.api_endpoint
		end

		if not override.cache then
			config.cache = nil
		else
			assert(type(override.cache) == 'table', 'cache must be a table or nil')
			assert(
				type(override.cache.dir_name) == 'string' and 1 <= #override.cache.dir_name,
				'cache.dir_name must be a non-empty string'
			)
			config.cache = override.cache
		end
	end

	log.fmt_debug('Got config=%s', config)

	local http_cache
	if config.cache then
		http_cache = cache.new(config.cache.dir_name)
	else
		log.fmt_debug('Using dummy cache')
		http_cache = cache.new_dummy()
	end

	return backend.new(config.api_endpoint, config.model, http.new(http_cache), env_get_api_key)
end

return openai
