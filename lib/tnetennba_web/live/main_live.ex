defmodule TnetennbaWeb.MainLive do
  use TnetennbaWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>
      Todays letters: <%= @current_letters %>
    </h1>
    <p>
      Today's target letter: <%= @current_letter %>
    </p>

    <.simple_form autocomplete="off" for={@form} phx-change="change" phx-submit="guess">
      <.input field={@form[:guess]} />
    </.simple_form>

    <h1>
      <%= length(@current_guesses) %>
    </h1>

    <ul>
      <li :for={{guess, time} <- @current_guesses}>
        <%= String.upcase(guess) %> <%= seconds_to_mins(time - @start_time) %>
      </li>
    </ul>
    """
  end

  def handle_event("guess", form_vals, socket) do
    guess = String.downcase(form_vals["guess"])
    word = socket.assigns.current_word
    letter = socket.assigns.current_letter
    now = System.os_time(:second)
    current_guesses = socket.assigns.current_guesses

    new_guesses =
      if Tnetennba.Native.is_good_guess(word, letter, guess) and
           !guess_in_current_guesses(current_guesses, guess) do
        [{guess, now} | current_guesses]
      else
        current_guesses
      end

    {:noreply,
     assign(socket, %{
       form: to_form(%{"guess" => ""}),
       current_guesses: new_guesses
     })}
  end

  def handle_event("change", form, socket) do
    {:noreply, assign(socket, :form, to_form(form))}
  end

  def mount(_params, _assigns, socket) do
    word = Tnetennba.Native.get_todays_word()

    letters =
      word
      |> String.to_charlist()
      |> Enum.shuffle()

    {:ok,
     assign(socket, %{
       days_since_ce: 0,
       temperature: 10,
       current_letters: letters,
       current_word: word,
       current_letter: "a",
       current_guesses: [],
       form: to_form(%{"guess" => ""}),
       start_time: System.os_time(:second),
       guess_times: []
     })}
  end

  def seconds_to_mins(seconds) do
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)

    "#{minutes}m#{secs}s"
  end

  def guess_in_current_guesses(guesses, guess) do
    guesses
    |> Enum.map(fn {guess, _} -> guess end)
    |> Enum.member?(guess)
  end
end
