defmodule Tnetennba.Native do
  use Rustler,
    otp_app: :tnetennba,
    crate: :tnetennba_native

  def is_good_guess(_word, _letter, _guess), do: :erlang.nif_error(:nif_not_loaded)
  def get_todays_word(), do: :erlang.nif_error(:nif_not_loaded)
  def get_todays_letter(), do: :erlang.nif_error(:nif_not_loaded)
end
