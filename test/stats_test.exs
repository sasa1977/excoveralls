defmodule ExCoveralls.StatsTest do
  use ExUnit.Case
  import Mock
  alias ExCoveralls.Stats
  alias ExCoveralls.Cover
  alias ExCoveralls.Settings

  @stats           [{{Stats, 1}, 0}, {{Stats, 2}, 1}]
  @modules         [Stats]
  @source          "test/fixtures/test.ex"
  @content         "defmodule Test do\n  def test do\n  end\nend\n"
  @trimmed         "defmodule Test do\n  def test do\n  end\nend"
  @count_hash      Enum.into([{1, 0}, {2, 1}], HashDict.new)
  @module_hash     Enum.into([{"test/fixtures/test.ex", @count_hash}], HashDict.new)
  @counts          [0, 1, nil, nil]
  @coverage        [{"test/fixtures/test.ex", @counts}]
  @source_info     [[name: "test/fixtures/test.ex",
                     source: @trimmed,
                     coverage: @counts
                   ]]
  @fixture_default Path.dirname(__ENV__.file) <> "/fixtures/default.json"
  @fixture_custom  Path.dirname(__ENV__.file) <> "/fixtures/skip_files.json"

  test_with_mock "calculate stats", Cover, [analyze: fn(_) -> {:ok, @stats} end, module_path: fn(_) -> @source end] do
    assert(Stats.calculate_stats([Stats]) == @module_hash)
  end

  test_with_mock "get source line count", Cover, [module_path: fn(_) -> @source end] do
    assert(Stats.get_source_line_count(@source) == 4)
  end

  test_with_mock "read module source", Cover, [module_path: fn(_) -> @source end] do
    assert(Stats.read_module_source(Stats) == @trimmed)
  end

  test "read source file" do
    assert(Stats.read_source(@source) == @trimmed)
  end

  test_with_mock "generate coverage", Cover, [module_path: fn(_) -> @source end] do
    assert(Stats.generate_coverage(@module_hash) == @coverage)
  end

  test_with_mock "generate source info", Cover, [module_path: fn(_) -> @source end] do
    assert(Stats.generate_source_info(@coverage) == @source_info)
  end

  test_with_mock "append sub app name", Cover, [module_path: fn(_) -> @source end] do
    stats = Stats.append_sub_app_name(@source_info, "subapp", "apps")
    assert(List.first(stats)[:name] == "apps/subapp/test/fixtures/test.ex")
  end

  test "trim empty suffix and prefix" do
    assert(Stats.trim_empty_prefix_and_suffix("\naaa\nbbb\n") == "aaa\nbbb")
  end
  @fixture_default Path.dirname(__ENV__.file) <> "/fixtures/default.json"

  test_with_mock "skip files", Settings.Files,
                   [default_file: fn -> @fixture_default end,
                    custom_file:  fn -> @fixture_custom end] do
    assert Stats.skip_files(@source_info) == []
  end
end
