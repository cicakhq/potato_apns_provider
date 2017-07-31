defmodule Parser do
  defp parse_list(chars, prefix) do
    [first | rest] = chars
    cond do
      is_space_char(first) ->
        parse_list(rest, prefix)
      first == ")" ->
        {prefix, rest}
      true ->
        {v, rem} = parse_expr(chars)
        parse_list(rem, prefix ++ [v])
    end
  end

  defp parse_string(chars, prefix) do
    [first | rest] = chars
    case first do
      "\"" ->
        {prefix, rest}
      "\\" ->
        [escaped_char | rem] = rest
        parse_string(rem, prefix <> escaped_char)
      ch ->
        parse_string(rest, prefix <> ch)
    end
  end

  defp is_symbol_start_char(ch) do
    (ch >= "a" && ch <= "z")
    || (ch >= "A" && ch <= "Z")
    || ch == "-"
    || ch == "_"
  end

  defp is_number_char(ch) do
    ch >= "0" && ch <= "9"
  end

  defp is_symbol_char(ch) do
    is_symbol_start_char(ch) || is_number_char(ch)
  end

  defp is_space_char(ch) do
    ch == " " || ch == "\n" || ch == "\r"
  end

  defp parse_symbol(chars, prefix) do
    if length(chars) > 0 do
      [first | rest] = chars
      cond do
        is_symbol_char(first) -> parse_symbol(rest, prefix <> first)
        true -> {String.to_atom(String.replace(String.downcase(prefix), "-", "_")), chars}
      end
    else
      {String.to_atom(String.replace(String.downcase(prefix), "-", "_")), chars}
    end
  end

  defp parse_number(chars, prefix) do
    if length(chars) > 0 do
      [first | rest] = chars
      if is_number_char(first) do
        parse_number(rest, prefix <> first)
      else
        {String.to_integer(prefix), chars}
      end
    else
      {String.to_integer(prefix), chars}
    end
  end

  defp parse_keyword(chars) do
    [first | rest] = chars
    cond do
      # Currently we'll just parse keywords like any other symbol
      is_symbol_start_char(first) -> parse_symbol(rest, first)
    end
  end

  defp parse_expr(chars) do
    [first | rest] = chars
    case first do
      "(" -> parse_list(rest, [])
      "\"" ->  parse_string(rest, "")
      ":" -> parse_keyword(rest)
      ch ->
        cond do
          is_space_char(ch) -> parse_expr(rest)
          is_symbol_start_char(ch) -> parse_symbol(rest, ch)
          is_number_char(ch) -> parse_number(rest, ch)
        end
    end
  end

  def parse_from_string(s) do
    {result, _} = parse_expr(String.codepoints(s))
    result
  end

  defp plist_to_map_private(l, prefix) do
    if length(l) == 0 do
      prefix
    else
      [key | value_and_rest] = l
      [value | rest] = value_and_rest
      plist_to_map_private(rest, prefix ++ [{key, value}])
    end      
  end

  def ex_plist_to_map(l) do
    plist_to_map_private(l, [])
  end
end
