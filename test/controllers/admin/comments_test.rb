require "test_helper"

class Admin::CommentsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "bandeja de sin responder" do
    get admin_comments_url
    assert_response :success
    assert_includes response.body, comments(:pending).text
    assert_not_includes response.body, comments(:question).text

    get admin_comments_url(status: "all")
    assert_includes response.body, comments(:question).text
  end

  test "responder como Ana Gaby" do
    comment = comments(:pending)
    assert_difference("Comment.count") do
      post reply_admin_comment_url(comment), params: { reply: { text: "¡Gracias por entrenar conmigo!" } }
    end
    reply = comment.replies.last
    assert_equal users(:admin), reply.user
    assert_equal comment.workout, reply.workout
    assert_not_includes Comment.unanswered, comment
  end

  test "respuesta vacía no se guarda" do
    assert_no_difference("Comment.count") do
      post reply_admin_comment_url(comments(:pending)), params: { reply: { text: "" } }
    end
    assert_equal "Escribe una respuesta antes de enviarla.", flash[:alert]
  end

  test "eliminar un comentario borra sus respuestas" do
    assert_difference("Comment.count", -2) do
      delete admin_comment_url(comments(:question))
    end
  end
end
