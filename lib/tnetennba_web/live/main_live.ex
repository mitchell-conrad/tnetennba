defmodule TnetennbaWeb.MainLive do
  require Logger
  use TnetennbaWeb, :live_view

  # TODO: Tidy this module up lmao

  def render(assigns) do
    ~H"""
    <%= if @new_record? do %>
      <.flash kind={:info}>New record!</.flash>
    <% end %>

    <h1>
      Todays letters: <%= letterise(@session_state.letters) %>
    </h1>
    <p>
      Today's target letter: <%= String.upcase(@current_letter) %>
    </p>
    <p>
      Today's global record: <%= @global_record %>
    </p>

    <.simple_form autocomplete="off" for={@form} phx-change="change" phx-submit="guess">
      <.input field={@form[:guess]} />
    </.simple_form>

    <h1>
      <%= length(@session_state.guesses) %>
    </h1>

    <ul>
      <li :for={[guess, time] <- @session_state.guesses}>
        <%= if guess == @session_state.word do %>
          <%= String.upcase(guess) %> <%= seconds_to_mins(time - @session_state.start_time) %>
        <% else %>
          <%= String.downcase(guess) %> <%= seconds_to_mins(time - @session_state.start_time) %>
        <% end %>
      </li>
    </ul>
    """
  end

  def handle_event("guess", form_vals, socket) do
    session_id = socket.assigns.session_id
    word = socket.assigns.session_state.word
    letter = socket.assigns.current_letter
    letters = socket.assigns.session_state.letters
    current_guesses = socket.assigns.session_state.guesses
    start_time = socket.assigns.session_state.start_time

    guess = String.downcase(form_vals["guess"])
    now = System.os_time()

    Logger.info(%{todays_word: word})

    new_guesses =
      if Tnetennba.Native.is_good_guess(word, letter, guess) and
           !guess_in_current_guesses(current_guesses, guess) do
        [[guess, now] | current_guesses]
      else
        current_guesses
      end

    new_record =
      if length(new_guesses) > length(current_guesses) do
        # only do a dynamo lookup & update on new local records
        case Tnetennba.DynamoDao.update_record(
               socket.assigns.dynamo_client,
               word,
               length(new_guesses)
             ) do
          {:ok, _, _} -> true
          _ -> false
        end
      else
        false
      end

    global_record =
      if new_record do
        length(new_guesses)
      else
        socket.assigns.global_record
      end

    new_session_state = %Tnetennba.Session{
      letters: letters,
      word: word,
      guesses: new_guesses,
      start_time: start_time
    }

    Task.async(fn ->
      Tnetennba.Session.put_session(
        socket.assigns.dynamo_client,
        session_id,
        new_session_state
      )
    end)

    {:noreply,
     assign(socket, %{
       form: to_form(%{"guess" => ""}),
       session_state: new_session_state,
       new_record?: new_record,
       global_record: global_record
     })}
  end

  def handle_event("change", form, socket) do
    {:noreply, assign(socket, :form, to_form(form))}
  end

  def mount(_params, session, socket) do
    word = Tnetennba.Native.get_todays_word()
    letter = Tnetennba.Native.get_todays_letter()
    session_id = session["session_id"]
    dynamo_client = AWS.Client.create("ap-southeast-2")

    {:ok, session_state} = Tnetennba.Session.get_session(dynamo_client, session_id)

    session_state =
      if session_state.word == word do
        session_state
      else
        %Tnetennba.Session{
          letters: Enum.shuffle(String.to_charlist(word)),
          word: word,
          guesses: [],
          start_time: System.os_time()
        }
      end

    global_record = Tnetennba.DynamoDao.get_record(dynamo_client, word)

    {:ok,
     assign(socket, %{
       session_id: session_id,
       session_state: session_state,
       current_letter: letter,
       form: to_form(%{"guess" => ""}),
       dynamo_client: dynamo_client,
       global_record: global_record,
       new_record?: false
     })}
  end

  def seconds_to_mins(time) do
    seconds = System.convert_time_unit(time, :native, :second)
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)

    "#{minutes}m#{secs}s"
  end

  def guess_in_current_guesses(guesses, guess) do
    guesses
    |> Enum.map(fn [guess, _] -> guess end)
    |> Enum.member?(guess)
  end

  def letterise(letters) do
    String.upcase("#{letters}")
  end
end
