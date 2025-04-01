local assert = require("luassert")
local mock = require("luassert.mock")

-- Mock the required modules
local logger_mock = mock(require("parrot.logger"), true)
local Job_mock = mock(require("plenary.job"), true)

-- Load the Ollama class
local Ollama = require("parrot.provider.ollama")

describe("Ollama", function()
  local ollama

  before_each(function()
    ollama = Ollama:new("http://localhost:11434/api/generate", "")
    assert.are.same(ollama.name, "ollama")
    -- Reset mocks
    logger_mock.error:clear()
    logger_mock.warning:clear()
    logger_mock.info:clear()
    logger_mock.debug:clear()
  end)

  describe("process_onexit", function()
    it("should log an error message when there's an API error", function()
      local input = vim.json.encode({
        error = "model 'llama5:latest' not found, try pulling it first",
      })

      ollama:process_onexit(input)

      assert
        .spy(logger_mock.error)
        .was_called_with("Ollama - error: model 'llama5:latest' not found, try pulling it first")
    end)

    it("should not log anything for successful responses", function()
      local input = vim.json.encode({ success = true })

      ollama:process_onexit(input)

      assert.spy(logger_mock.error).was_not_called()
    end)

    it("should handle invalid JSON gracefully", function()
      local input = "invalid json"

      ollama:process_onexit(input)

      assert.spy(logger_mock.error).was_not_called()
    end)
  end)

  describe("process_stdout", function()
    it("should extract content from a valid response", function()
      local input =
        '{"model":"llama3:latest","created_at":"2024-07-16T15:07:15.378379Z","message":{"role":"assistant","content":","},"done":false}'

      local result = ollama:process_stdout(input)

      assert.equals(",", result)
    end)

    it("should handle responses without content", function()
      local input =
        '{"model":"mistral:latest","created_at":"2024-07-16T15:07:27.808873Z","message":{"role":"assistant","content":""},"done_reason":"stop","done":true,"total_duration":9668777042,"load_duration":8020184084,"prompt_eval_count":414,"prompt_eval_duration":1276782000,"eval_count":13,"eval_duration":366249000}'

      local result = ollama:process_stdout(input)

      assert.equals("", result)
    end)

    it("should return nil for non-matching responses", function()
      local input = '{"type":"other_response"}'

      local result = ollama:process_stdout(input)

      assert.is_nil(result)
    end)

    it("should handle invalid JSON gracefully", function()
      local input = "invalid json"

      local result = ollama:process_stdout(input)

      assert.is_nil(result)
    end)
  end)

  -- describe("preprocess_payload", function()
  -- it("should trim whitespace from message content", function()
  --   local payload = {
  --     messages = {
  --       { role = "user", content = "  Hello, Ollama!  " },
  --       { role = "assistant", content = " How can I help?  " }
  --     }
  --   }
  --
  --   local result = ollama:preprocess_payload(payload)
  --
  --   assert.equals("Hello, Ollama!", result.messages[1].content)
  --   assert.equals("How can I help?", result.messages[2].content)
  -- end)

  -- it("should filter payload parameters", function()
  --   utils_mock.filter_payload_parameters.returns({ filtered = true })
  --
  --   local payload = { messages = {}, temperature = 0.7, invalid_param = "test" }
  --
  --   local result = ollama:preprocess_payload(payload)
  --
  --   assert.is_true(result.filtered)
  --   assert.spy(utils_mock.filter_payload_parameters).was_called_with(available_api_parameters, payload)
  -- end)
  -- end)

  describe("verify", function()
    it("should always return true", function()
      assert.is_true(ollama:verify())
    end)
  end)

  describe("predefined models", function()
    it("should return predefined list of available models.", function()
      local my_models = {
        "gemma3",
        "llama3",
      }
      ollama = Ollama:new("http://localhost:11434/api/generate", "", my_models)
      assert.are.same(ollama.models, my_models)
      assert.are.same(ollama:get_available_models(), my_models)
    end)
  end)
end)
