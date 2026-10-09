require "test_helper"

class YoutubeThumbnailTest < ActiveSupport::TestCase
  test "usa la de mejor calidad que exista" do
    existing = [ "https://i.ytimg.com/vi/abcdefghijk/sddefault.jpg", "https://i.ytimg.com/vi/abcdefghijk/hqdefault.jpg" ]
    YoutubeThumbnail.stub(:exists?, ->(url) { existing.include?(url) }) do
      assert_equal "https://i.ytimg.com/vi/abcdefghijk/sddefault.jpg", YoutubeThumbnail.fetch("abcdefghijk")
    end

    YoutubeThumbnail.stub(:exists?, ->(_) { true }) do
      assert_equal "https://i.ytimg.com/vi/abcdefghijk/maxresdefault.jpg", YoutubeThumbnail.fetch("abcdefghijk")
    end
  end

  test "regresa nil si el video no existe, no hay ID o YouTube falla" do
    YoutubeThumbnail.stub(:exists?, ->(_) { false }) do
      assert_nil YoutubeThumbnail.fetch("abcdefghijk")
    end
    assert_nil YoutubeThumbnail.fetch(nil)
    YoutubeThumbnail.stub(:exists?, ->(_) { raise SocketError, "sin red" }) do
      assert_nil YoutubeThumbnail.fetch("abcdefghijk")
    end
  end
end
