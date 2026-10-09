require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workout = workouts(:two)
  end

  test "comentar pide sesión" do
    assert_no_difference("Comment.count") do
      post workout_comments_url(@workout), params: { comment: { text: "Hola" } }
    end
    assert_redirected_to new_user_session_url
  end

  test "el autor sale de la sesión y no se puede responder como Ana Gaby" do
    sign_in users(:member)
    assert_difference("Comment.count") do
      post workout_comments_url(@workout), params: {
        comment: { text: "¡Gracias!", user_id: users(:admin).id, parent_id: comments(:pending).id }
      }
    end
    comment = Comment.order(:id).last
    assert_equal users(:member), comment.user
    assert_nil comment.parent_id
    assert_redirected_to workout_url(@workout, anchor: "comentarios")
  end

  test "comentario vacío no se guarda" do
    sign_in users(:member)
    assert_no_difference("Comment.count") do
      post workout_comments_url(@workout), params: { comment: { text: " " } }
    end
    assert_equal "Escribe tu comentario antes de publicarlo.", flash[:alert]
  end

  test "las rutas viejas de comentarios ya no existen" do
    sign_in users(:member)
    delete "/comments/#{comments(:question).id}"
    assert_response :not_found
    assert Comment.exists?(comments(:question).id)
  end
end
