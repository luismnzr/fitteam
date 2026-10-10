require "test_helper"
require "vips"

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

  test "recorta las barras negras de las 4:3 y reduce al ancho pedido" do
    hq = jpeg(480, 360)
    image = Vips::Image.new_from_buffer(YoutubeThumbnail.render(hq, max_width: 800), "")
    assert_equal [ 480, 270 ], [ image.width, image.height ]

    maxres = jpeg(1280, 720)
    image = Vips::Image.new_from_buffer(YoutubeThumbnail.render(maxres, max_width: 800), "")
    assert_equal [ 800, 450 ], [ image.width, image.height ]

    assert_same maxres, YoutubeThumbnail.render(maxres), "una 16:9 sin reducir se sirve tal cual"
  end

  test "si la imagen no se puede leer, regresa la original" do
    assert_equal "no es una imagen", YoutubeThumbnail.render("no es una imagen", max_width: 800)
  end

  private

  def jpeg(width, height)
    Vips::Image.black(width, height, bands: 3).jpegsave_buffer
  end
end
