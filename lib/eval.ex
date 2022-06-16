defmodule Smalc do
  import BNum

  # Running and outputting

  def output(expr) do
    case Smalc.run(expr) do
      {:ok, value} ->
        IO.puts(value)
      {:error, line, message} ->
        IO.puts("""
        Line #{line}
        #{message}
        """)
    end
  end

  def preprocessor(code), do: code |> String.replace("[", "(((") |> String.replace("]", "))")

  def run(code) do
    with {:ok, tokens, _} <- :lexer.string(to_charlist(preprocessor(code))),
         {:ok, ast} <- :parser.parse(tokens) do
      {:ok, ast |> eval(%{'PI' => "3"})}
    end
    |> Error.normalize_value()
  end

  def ast(code) do
    with {:ok, tokens, _} <- :lexer.string(to_charlist(preprocessor(code))),
         {:ok, ast} <- :parser.parse(tokens), do:
      {:ok, ast}
  end

  # AST evaluation

  def eval({:assign, {:ident, _, name}, e1, e2}, ctx) do
    new_ctx = ctx |> Map.put(name, eval(e1, ctx))
    eval(e2, new_ctx)
  end
  def eval({:ident, _, name}, ctx) do
    id = name |> to_string() |> String.reverse() |> to_charlist()
    if ctx |> Map.has_key?(id) do
      ctx |> Map.get(id)
    else
      name
    end
  end
  def eval({:add, e1, e2}, ctx), do: base16_op(eval(e1, ctx), eval(e2, ctx), &+/2)
  def eval({:mul, e1, e2}, ctx), do: base16_op(eval(e1, ctx), eval(e2, ctx), &*/2)
  def eval({:sub, e1, e2}, ctx), do: base16_op(eval(e1, ctx), eval(e2, ctx), &-/2)
  def eval({:divi, e1, e2}, ctx), do: base16_op(eval(e1, ctx), eval(e2, ctx), &//2)
  def eval({:pow, e1, e2}, ctx), do: base16_op(eval(e1, ctx), eval(e2, ctx), &**/2)
  def eval({:mod, e1, e2}, ctx), do: base16_op(eval(e1, ctx), eval(e2, ctx), &Integer.mod/2)
  def eval(_, _), do: {:error, "unknown token"}
end