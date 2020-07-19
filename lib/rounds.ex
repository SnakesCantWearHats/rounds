defmodule Rounds do
  @moduledoc """
  Documentation for `Rounds`.
  """

  @doc """

  """
  @filename "output.bin"
  @volume 0.3
  @sample_rate 48_000
  @pitch_standard 440.0

  def start do
    duration = 1.0

    [
      set_release(set_attack(get_note("A4", duration), 0.2), 0.2),
      set_release(set_attack(get_note("A4", duration), 0.2), 0.2),
      set_release(set_attack(get_note("A4", duration), 0.2), 0.2),
      set_release(set_attack(get_note("A4", duration), 0.2), 0.2),
      set_release(set_attack(get_note("A4", duration), 0.2), 0.2),
    ]
    |> List.flatten()
    |> set_volume(@volume)
  end

  @spec get_note(String.t(), float) :: [float]
  def get_note(note, duration) do
    get_wave(get_frequency(note), duration)
  end

  @spec get_step(number) :: float
  def get_step(pitch) do
    pitch * 2 * :math.pi() / @sample_rate
  end

  @spec set_volume([float], float) :: [float]
  def set_volume(samples, volume) do
    samples
    |> Enum.map(&(&1 * volume))
  end

  @spec get_wave(number, float) :: [float]
  def get_wave(pitch, duration) do
    1..Kernel.round(@sample_rate * duration)
    |> Enum.map(&(&1 * get_step(pitch)))
    |> Enum.map(&:math.sin/1)
  end

  @spec convert_to_bitstring([float]) :: bitstring
  def convert_to_bitstring(list) do
    list
    |> Enum.into(<<>>, fn bit -> <<bit::float-size(32)>> end)
  end

  @spec write_to_file(bitstring, String.t()) :: any
  def write_to_file(content, filename) do
    {:ok, file} = File.open(filename, [:write])
    IO.binwrite(file, content)
    File.close(file)
  end

  def do_it do
    start()
    |> convert_to_bitstring()
    |> write_to_file(@filename)

    "ffplay -f f32be -ar 48000 -nodisp -autoexit #{@filename}"
    |> String.to_charlist()
    |> :os.cmd()

    :ok
  end

  @spec get_frequency(String.t()) :: number
  def get_frequency(note) do
    case note do
      "A4" -> 0
      "As4" -> 1
      "B4" -> 2
      "C5" -> 3
      "Cs5" -> 4
      "D5" -> 5
      "Ds5" -> 6
      "E5" -> 7
      "F5" -> 8
      "Fs5" -> 9
      "G5" -> 10
      "Gs5" -> 11
      "A5" -> 12
      _ -> raise "Wrong note"
    end
    |> semitones_to_frequency
  end

  defp semitones_to_frequency(semitones) do
    :math.pow(:math.pow(2, 1.0 / 12.0), semitones) * @pitch_standard
  end

  @spec set_attack([float], float) :: [float]
  def set_attack(note, till) do
    attack_time = Kernel.round (@sample_rate * till)

    0..attack_time
    |> Enum.map(&(&1 / attack_time))
    |> Enum.zip(note)
    |> Enum.into([], fn {a, b} -> a * b end)
    |> Enum.concat(Enum.slice(note, attack_time, length(note)))
  end

  def set_release(note, from) do
    release_time = Kernel.round (@sample_rate * from)

    0..release_time
    |> Enum.map(&(&1 / release_time))
    |> Enum.zip(Enum.reverse(note))
    |> Enum.into([], fn {a, b} -> a * b end)
    |> Enum.reverse()
    |> (fn tail, note -> Enum.slice(note, release_time, length(note)) ++ tail end).(note)
  end
end
