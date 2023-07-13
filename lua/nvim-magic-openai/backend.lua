local backend = {}

local completion = require('nvim-magic-openai._completion')
local log = require('nvim-magic-openai._log')
local buffer = require('nvim-magic._buffer')
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
    --print(compl)
		success(compl)
	end, fail)
end

function BackendMethods:chat_content_QA(prompt, filename, chunks, chunk_index, max_tokens, success, fail)
	stops = nil -- OpenAI API does not accept empty array for stops
	log.fmt_debug(
		'Fetching async completion prompt_length=%s max_tokens=%s stops=%s',
		#prompt,
		max_tokens,
		tostring(stops)
	)

   if chunk_index > #chunks then
      return
   end

   local req_body = completion.new_indexer_request(self.chat_index, chunks[chunk_index], prompt, self.model, max_tokens, stops)
   local req_body_json = vim.fn.json_encode(req_body)

   self.http:post(self.api_endpoint, req_body_json, self.get_api_key(), function(body)
   local compl = completion.extract_from(body)
   
   local ok, compl = pcall(vim.fn.json_decode, compl)

   if ok and compl.action == "add" then
       if compl.info then
         -- If the table is not full, insert the item
         if #self.chat_index < self.chat_index_max then
            table.insert(self.chat_index, compl.info)
         else
            -- If the table is full, overwrite the item at the current position
            self.chat_index[self.chat_index_pos + 1] = compl.info  -- Lua uses 1-based indexing
         end

         -- Increment the pointer and take modulo 15 to ensure it stays within [0, 14]
         self.pointer = (self.chat_index_pos + 1) % self.chat_index_max
       end
   elseif ok and compl.action == "update" then
       if compl.item and compl.info then
          if type(compl.item) == "string" then
              compl.item = tonumber(compl.item)
          end
          if compl.info and self.chat_index[compl.item] then
              self.chat_index[compl.item] = compl.info -- update the content at this index
          end
       end
   elseif ok and compl.action == "nothing" then
       -- print("Action is 'nothing'")
   end

      if chunk_index == #chunks then
         -- Now, use the index and answer the question
         local req_body = completion.new_doc_qa_answer(self.chat_index, filename, prompt, self.model, max_tokens, stops)
         local req_body_json = vim.fn.json_encode(req_body)
         local percentage = (chunk_index / #chunks) * 100
         local formatted_percentage = string.format("%.2f%%", percentage)
         local update_msg = "Processed " .. chunk_index .. " out of " .. #chunks .. " chunks of the document... (" .. formatted_percentage .. ")"
         if chunk_index == 1 then 
         buffer.append_end(self:get_chat_buffer(), update_msg) 
         else
            buffer.reset_last(self:get_chat_buffer(), update_msg)
         end

         self.http:post(self.api_endpoint, req_body_json, self.get_api_key(), function(body)
         local compl = completion.extract_from(body)
         success(compl)
          table.insert(self.chat_history, {
            role = "user",
            content = prompt
          })
          table.insert(self.chat_history, {
            role = "assistant",
            content = compl
          })


         end, fail)
      elseif chunk_index < #chunks then
         local percentage = (chunk_index / #chunks) * 100
         local formatted_percentage = string.format("%.2f%%", percentage)
         local update_msg = "Processed " .. chunk_index .. " out of " .. #chunks .. " chunks of the document... (" .. formatted_percentage .. ")"
         if chunk_index == 1 then 
         buffer.append_end(self:get_chat_buffer(), update_msg) 
         else
            buffer.reset_last(self:get_chat_buffer(), update_msg)
         end
         self:chat_content_QA(prompt, filename, chunks, chunk_index + 1, max_tokens, success, fail)
      end
   end, fail)

end


function BackendMethods:get_chat_length()
  return #self.chat_history
end

function BackendMethods:set_chat_buffer(bufno)
  self.chat_buffer = bufno
end

function BackendMethods:get_chat_buffer(bufno)
  return self.chat_buffer
end

function BackendMethods:chat_reset()
  self.chat_history = {}
  self.chat_index = {}
  self.chat_index_pos = 0
end

function BackendMethods:indexer_reset()
  self.chat_index = {}
  self.chat_index_pos = 0
end

local BackendMt = { __index = BackendMethods }

function backend.new(api_endpoint, model, http, api_key_fn)
	return setmetatable({
		api_endpoint = api_endpoint,
		get_api_key = api_key_fn,
		http = http,
		model = model,
    chat_history = {},
    chat_index = {},
    chat_index_pos = 0,
    chat_index_max = 16,
    chat_buffer = 0
	}, BackendMt)
end

return backend
