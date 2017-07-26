defmodule LispUtil do
  defp parse_plist(l, prefix) do
    if length(l) == 0 do
      prefix
    else
      [key | value_and_rest] = l
      [value | rest] = value_and_rest
      parse_plist(rest, prefix ++ [{key, value}])
    end      
  end

  def lisp_plist_to_map(l) do
    parse_plist(l, [])
  end
end
