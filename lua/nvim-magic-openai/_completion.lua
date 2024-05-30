local completion = {}

function completion.new_request(prompt, model, max_tokens, stops)
   assert(type(prompt) == 'string', 'prompt must be a string')
   assert(type(max_tokens) == 'number', 'max tokens must be a number')
   if stops then
      assert(type(stops) == 'table', 'stops must be an array of strings')
   end

   return {
      messages = {
         { role = "system",
                               content =
            "You are an expert programmer. All you do is respond in code, not text or formatting. Derive the type of code you type in depending on the input code or question. Try to make the code look good, and include comments unless stated otherwise. Answer with the indentation level as the code provided if the user provides code snippets. Never embedd your code in backticks in your answers." },
         { role = "user",   content = prompt }
      },
      model = model,
      stream = false,
--      temperature = 0,
--      max_tokens = max_tokens,
--      n = 1,
--      top_p = 1,
--      stop = stops,
--      frequency_penalty = 0,
--      presence_penalty = 0,
   }
end

function completion.new_chat_request(history, prompt, model, max_tokens, stops)
   assert(type(prompt) == 'string', 'prompt must be a string')
   assert(type(max_tokens) == 'number', 'max tokens must be a number')
   if stops then
      assert(type(stops) == 'table', 'stops must be an array of strings')
   end

   local messages = {
      { role = "system",
                            content =
         "You are a friendly assistant. You live inside a text editor. Someone is working and might ask you techical questions. Try to answer as best as you can." },
      { role = "user",   content = prompt }
   }

   -- Insert all entries of table A between the first and second elements in messages
   for i, entry in ipairs(history) do
      table.insert(messages, i + 1, entry)
   end

   return {
      messages = messages,
      model = model,
--      temperature = 0,
--      max_tokens = max_tokens,
--      n = 1,
--      top_p = 1,
--      stop = stops,
--      frequency_penalty = 0,
--      presence_penalty = 0,
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

   local answer_prompt = "You have read a file named '" ..
   filename ..
   "' and collected the following information:\n\n" ..
   indexed .. "\n\nNow, using this information, answer the following question: '" .. prompt .. "'"


   local messages = {
      { role = "system", content = answer_prompt },
   }

   return {
      messages = messages,
      model = model,
--      temperature = 0,
--      max_tokens = max_tokens,
--      n = 1,
--      top_p = 1,
--      stop = stops,
--      frequency_penalty = 0,
--      presence_penalty = 0,
   }
end

function completion.new_codebase_gen_clarify_request(prompt, model, max_tokens, stops)
   assert(type(prompt) == 'string', 'prompt must be a string')
   assert(type(max_tokens) == 'number', 'max tokens must be a number')
   if stops then
      assert(type(stops) == 'table', 'stops must be an array of strings')
   end

   local answer_prompt =
   "You are on a quest of designing a software architecture. The software projects indended goal is stated by a customer. The customer has, when asked 'what do you want to be built?' requested the following: '" ..
   prompt ..
   "'\n\nYou now get an oportunity to ask three clarifying questions that you want the customer to clarify. These questsions, when anwered, will help you desing the software. Generate three questions, you answer should just be a JSON string with the field 'questions' containing three questions strings. It could look like this: {\"questions\":[\"question 1\",\"question 2\", \"question 3\"]}. Answer only in JSON. What are your three clarifying questions?"


   local messages = {
      { role = "system", content = answer_prompt },
   }

   return {
      messages = messages,
      model = model,
--      temperature = 0,
--      max_tokens = max_tokens,
--      n = 1,
--      top_p = 1,
--      stop = stops,
--      frequency_penalty = 0,
--      presence_penalty = 0,
   }
end

function completion.new_codebase_gen_file_listing(prompt, clarify, model, max_tokens, stops)
   assert(type(prompt) == 'string', 'prompt must be a string')
   assert(type(max_tokens) == 'number', 'max tokens must be a number')
   if stops then
      assert(type(stops) == 'table', 'stops must be an array of strings')
   end

   local clarify_indexed = ""
   if next(clarify) == nil then
      clarify = "(the list is empty)"
   else
      for question, answer in pairs(clarify) do
         clarify_indexed = clarify_indexed .. question .. ":" .. answer .. "\n"
      end
   end

   local answer_prompt =
   "You are on a quest of designing a software architecture. The software projects indended goal is stated by a customer. The customer has, when asked 'what do you want to be built?' requested the following: '" ..
   prompt ..
   "'\n\nAsked to clarify some details, the following questions have been answered by the the customer (question: answer):\n\n" ..
   clarify_indexed ..
   "\n\nYou now get an oportunity to declare what files will be needed in the software architecture. It is advised to always include a README.md file in the root of the codebase. You will provide a JSON string as a response. The JSON string will include a field called 'files'. This contains a list of items. Each item has two fields, 'name' which is the filename, 'description' which is the description of what role the file has in the software architecture. Details that are important to get right across the codebase should be included in the description, such as classes, function signature (names and parameters) intended to be used and available to the codebase from the file. If this file is software code, write a condensed summary of what classes, function signatures (names and parameters) and definitions are available in this file that can be interesting for the rest of the codebase. Don't go into specifics or the details of the implementation, just make sure to state what is available to the outside. You want to help construct a codebase and you now need to document what each file will include. Answer only in JSON. An example of such a listing JSON object is like this: {\"files\":[{\"name\":\"main.js\",\"description\":\"The main Javascript application file that contains the logic. It contains the class Film that only has two methods: start(seconds) and stop().\"},{\"name\":\"index.html\",\"description\": \"An HTML file that can be opened in the browser to display the game. Ids used are 'canvas' for a <canvas> element, 'score' for a <p> element\"},{\"name\":\"README.md\",\"description\":\"A markdown README file describing the project.\"}]}. Make a custom one for your customers request. Answer only in JSON."

   local messages = {
      { role = "system", content = answer_prompt },
   }

   return {
      messages = messages,
      model = model,
--      temperature = 0,
--      max_tokens = max_tokens,
--      n = 1,
--      top_p = 1,
--      stop = stops,
--      frequency_penalty = 0,
--      presence_penalty = 0,
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

   local indexer_prompt =
   "You are reading through pages of a document searching for answers to a question. The question is: '" ..
   prompt ..
   "'.\n\nYou have already collected the following information items from the document (in a list of 0-n items where n is at most 15):\n\n" ..
   indexed ..
   "\n\n. I will provide a new page from the document. If the page contains information that helps answer the question you can do three things. Either add a new information point, which might be a summary of the relevant information, to the list, or you can update the content of one item in the list or you can do nothing. Your answer should be in correct JSON format. Answer with the field \"action\" which is either \"nothing\", \"add\" or \"update\". If add, then provide the information in the field \"info\" like this: {\"action\":\"add\",\"info\":\"new content\"}. If nothing, then answer like this: {\"action\":\"nothing\"}. If update the answer like this, where X is an integer corresponding to an index in the list: {\"action\":\"update\",\"item\":X,\"info\":\"...updated content...\"}. Help me establish this list of information points that I can use to be able to answer the question. Don't explain why you answer like you answer, just provide the JSON string. Here is the new page from the document:\n\n" ..
   doc_page

   local messages = {
      { role = "system", content = indexer_prompt },
   }

   return {
      messages = messages,
      model = model,
--      temperature = 0,
--      max_tokens = max_tokens,
--      n = 1,
--      top_p = 1,
--      stop = stops,
--      frequency_penalty = 0,
--      presence_penalty = 0,
   }
end

function completion.new_codebase_gen_minify_file_request(file_name, file_content, model, max_tokens, stops)
   assert(type(file_name) == 'string', 'prompt must be a string')
   assert(type(max_tokens) == 'number', 'max tokens must be a number')
   if stops then
      assert(type(stops) == 'table', 'stops must be an array of strings')
   end

   local answer_prompt =
   "You are on a quest of designing a software code base. You write the code base one file at a time. I want you to document the relevent parts for the code base that you just have written. You have just written the following file '" .. file_name .. "':\n\n" ..
   file_content .. "\n\n" ..
   "If this file is software code, write a condensed summary of what classes, function signatures (names and parameters) and definitions are available in this file that can be interesting for the rest of the codebase. You want to help construct a codebase and you now need to document what is available in this file. Don't go into specifics or the details of the implementation, just make sure to state what is available to the outside."

   local messages = {
      { role = "system", content = answer_prompt },
   }

   return {
      messages = messages,
      model = model,
--      temperature = 0,
--      max_tokens = max_tokens,
--      n = 1,
--      top_p = 1,
--      stop = stops,
--      frequency_penalty = 0,
--      presence_penalty = 0,
   }
end


function completion.new_codebase_gen_file_request(prompt, clarify, files, file, model, max_tokens, stops)
   assert(type(prompt) == 'string', 'prompt must be a string')
   assert(type(max_tokens) == 'number', 'max tokens must be a number')
   if stops then
      assert(type(stops) == 'table', 'stops must be an array of strings')
   end
   local files_e = vim.fn.json_encode(files)

   local clarify_indexed = ""
   if next(clarify) == nil then
      clarify = "(the list is empty)"
   else
      for question, answer in pairs(clarify) do
         clarify_indexed = clarify_indexed .. question .. ":" .. answer .. "\n"
      end
   end

   local implementer_prompt =
   "You are on a quest of designing a software architecture. The software projects indended goal is stated by a customer. The customer has, when asked 'what do you want to be built?' requested the following: '" ..
   prompt ..
   "'\n\nAsked to clarify some details, the following questions have been answered by the the customer (question: answer):\n\n" ..
   clarify_indexed ..
   "\n\nAn outline of the file system has already been specified. The software file system is described in the JSON string:\n\n" ..
   files_e ..
   "\n\nYou now get to write a file from the codebase directly to the file system. The file in the codebase that you should implement is: " ..
   "'" .. file.name .. "'." ..
   "\n\nSince you are writing directly to the file system, an empty file with the name " .. file.name .. " has been created. Your output will feed directly to this file, so answer only with the file content and nothing else (no additional formating or meta data). If you are writing code, answer only with the plain file content and don't embedd the code inside backticks. Don't start your answer with ```[javascript or python or whather] - just write the file content without that formatting since you are writing directly to file. Base your implementation on the content of the outline. Don't make any assumptions on definitions taken from other files if they aren't already specified in the outline. Only what is is the outline can be assumed to be available from the other files in the codebase."

   local messages = {
      { role = "system", content = implementer_prompt },
   }

   return {
      messages = messages,
      model = model,
--      max_tokens = max_tokens,
--      temperature = 0,
--      n = 1,
--      top_p = 1,
--      stop = stops,
--      frequency_penalty = 0,
--      presence_penalty = 0,
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
