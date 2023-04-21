local backend = {}

local completion = require('nvim-magic-openai._completion')
local log = require('nvim-magic-openai._log')

local BackendMethods = {}

function BackendMethods:complete(lines, max_tokens, stops, success, fail)
	if type(stops) == 'table' and #stops == 0 then
		stops = nil -- OpenAI API does not accept empty array for stops
	end
	local prompt = table.concat(lines, '\n')
	log.fmt_debug(
		'Fetching async completion prompt_length=%s max_tokens=%s stops=%s',
		#prompt,
		max_tokens,
		tostring(stops)
	)

	local req_body = completion.new_request(prompt, self.model, max_tokens, stops)
	local req_body_json = vim.fn.json_encode(req_body)

	self.http:post(self.api_endpoint, req_body_json, self.get_api_key(), function(body)
		local compl = completion.extract_from(body)
		success(compl)
	end, fail)
end

function BackendMethods:chat(prompt, max_tokens, success, fail)
	stops = nil -- OpenAI API does not accept empty array for stops
	log.fmt_debug(
		'Fetching async completion prompt_length=%s max_tokens=%s stops=%s',
		#prompt,
		max_tokens,
		tostring(stops)
	)

	local req_body = completion.new_chat_request(self.chat_history, prompt, self.model, max_tokens, stops)
	local req_body_json = vim.fn.json_encode(req_body)

	self.http:post(self.api_endpoint, req_body_json, self.get_api_key(), function(body)
		local compl = completion.extract_from(body)
    table.insert(self.chat_history, {
      role = "user",
      content = prompt
    })
    table.insert(self.chat_history, {
      role = "assistant",
      content = compl
    })
    print(compl)
		success(compl)
	end, fail)
end


local BackendMt = { __index = BackendMethods }

function backend.new(api_endpoint, model, http, api_key_fn)
	return setmetatable({
		api_endpoint = api_endpoint,
		get_api_key = api_key_fn,
		http = http,
		model = model,
    chat_history = {}
	}, BackendMt)
end

return backend
