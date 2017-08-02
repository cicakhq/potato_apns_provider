defmodule APNS_Listener.Callback do
  def error(%APNS.Error{error: error, message_id: message_id}, token \\ "unknown token") do
    APNS.Logger.warn(~s(error "#{error}" for message #{inspect(message_id)} to #{token}))
  end

#  def feedback(%APNS.Feedback{token: token}) do
#    APNS.Logger.info(~s(feedback received for token #{token}))
#  end

  def feedback(data = %APNS.Feedback{}) do
    APNS.Logger.info("Got feedback: #{inspect(data)}")
  end

  def test do
    message = APNS.Message.new
    |> Map.put(:token, "89CFE1EE650F7E2C0DFE663E919B7B5A6E27A3C0C47CC25B71FAB0419BF9338A")
    |> Map.put(:alert, "Another test message")
    APNS.push(:dev_pool, message)
    APNS.Logger.info("Send message: #{inspect(message)}")
  end
end
