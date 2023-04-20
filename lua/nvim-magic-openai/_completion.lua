local completion = {}

function completion.new_request(prompt, model, max_tokens, stops)
	assert(type(prompt) == 'string', 'prompt must be a string')
	assert(type(max_tokens) == 'number', 'max tokens must be a number')
	if stops then
		assert(type(stops) == 'table', 'stops must be an array of strings')
	end

	return {
		messages = {
         {role = "system", content = "You are an expert programmer. All you do is respond in code, not text or formatting. Derive the type of code you type in depending on the input code or question. Try to make the code look good, and include comments unless stated otherwise."},
         {role = "user", content = prompt}
      },
    model = model,
		temperature = 0,
		max_tokens = max_tokens,
		n = 1,
		top_p = 1,
		stop = stops,
		frequency_penalty = 0,
		presence_penalty = 0,
	}
end

function completion.extract_from(res_body)
	local ok, decoded = pcall(vim.fn.json_decode, res_body)
	if not ok then
		local errmsg = decoded
		error(string.format("couldn't decode response body errmsg=%s body=%s", errmsg, res_body))
	end
	assert(decoded.choices ~= nil, 'no choices returned')
	return decoded.choices[1].message.content
end

return completion
