local completion = {}

function completion.new_request(prompt, model, max_tokens, stops)
	assert(type(prompt) == 'string', 'prompt must be a string')
	assert(type(max_tokens) == 'number', 'max tokens must be a number')
	if stops then
		assert(type(stops) == 'table', 'stops must be an array of strings')
	end

	return {
		messages = {
         {role = "system", content = "You are an expert programmer. All you do is respond in code, not text or formatting. Derive the type of code you type in depending on the input code or question. Try to make the code look good, and include comments unless stated otherwise. Mind the indentation of the code."},
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

function completion.new_chat_request(history, prompt, model, max_tokens, stops)
	assert(type(prompt) == 'string', 'prompt must be a string')
	assert(type(max_tokens) == 'number', 'max tokens must be a number')
	if stops then
		assert(type(stops) == 'table', 'stops must be an array of strings')
	end

  local messages = {
       {role = "system", content = "You are a friendly assistant. You live inside a text editor. Someone is working and might ask you techical questions. Try to answer as best as you can."},
      {role = "user", content = prompt}
  }

  -- Insert all entries of table A between the first and second elements in messages
  for i, entry in ipairs(history) do
      table.insert(messages, i + 1, entry)
  end

	return {
		messages = messages,
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



function completion.new_doc_qa_answer(index, filename, prompt, model, max_tokens, stops)
	assert(type(prompt) == 'string', 'prompt must be a string')
	assert(type(max_tokens) == 'number', 'max tokens must be a number')
	if stops then
		assert(type(stops) == 'table', 'stops must be an array of strings')
	end

   local indexed = ""
   if next(index) == nil then
      indexed = "(the list is empty)"
   else
      for i, v in ipairs(index) do
         indexed = indexed .. i .. ":" .. v .. "\n"
      end
   end

   local answer_prompt = "You have read a file named '" .. filename .. "' and collected the following information:\n\n" .. indexed .. "\n\nNow, using this information, answer the following question: '" .. prompt .. "'"


  local messages = {
       {role = "system", content = answer_prompt},
  }

	return {
		messages = messages,
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



function completion.new_indexer_request(index, doc_page, prompt, model, max_tokens, stops)
	assert(type(prompt) == 'string', 'prompt must be a string')
	assert(type(max_tokens) == 'number', 'max tokens must be a number')
	if stops then
		assert(type(stops) == 'table', 'stops must be an array of strings')
	end

   local indexed = ""
   if next(index) == nil then
      indexed = "(the list is empty)"
   else
      for i, v in ipairs(index) do
         indexed = indexed .. i .. ":" .. v .. "\n"
      end
   end

   local indexer_prompt =  "You are reading through pages of a document searching for answers to a question. The question is: '" .. prompt .. "'.\n\nYou have already collected the following information items from the document (in a list of 0-n items where n is at most 15):\n\n" .. indexed .. "\n\n. I will provide a new page from the document. If the page contains information that helps answer the question you can do three things. Either add a new information point, which might be a summary of the relevant information, to the list, or you can update the content of one item in the list or you can do nothing. Your answer should be in correct JSON format. Answer with the field \"action\" which is either \"nothing\", \"add\" or \"update\". If add, then provide the information in the field \"info\" like this: {\"action\":\"add\",\"info\":\"new content\"}. If nothing, then answer like this: {\"action\":\"nothing\"}. If update the answer like this, where X is an integer corresponding to an index in the list: {\"action\":\"update\",\"item\":X,\"info\":\"...updated content...\"}. Help me establish this list of information points that I can use to be able to answer the question. Don't explain why you answer like you answer, just provide the JSON string. Here is the new page from the document:\n\n" .. doc_page 

  local messages = {
       {role = "system", content = indexer_prompt},
  }

	return {
		messages = messages,
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
