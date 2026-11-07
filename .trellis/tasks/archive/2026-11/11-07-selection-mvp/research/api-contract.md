# Chat completions contract

Primary reference: https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create

The client sends a user-provided full HTTPS endpoint unchanged, POST JSON model/messages/stream:false, Authorization Bearer key, and parses choices[0].message.content. JSON structure is requested through the system instruction rather than a provider-specific response_format requirement. OpenAI-compatible providers may differ; a real configured provider is still required for final end-to-end validation. Tests intercept all traffic using URLProtocol.
