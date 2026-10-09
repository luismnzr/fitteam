# Comentarios de las usuarias en un workout. Desde el sitio solo se pueden
# crear; moderarlos y responderlos vive en Admin::CommentsController.
class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    workout = Workout.find(params[:workout_id])
    # El autor sale de la sesión, no del formulario.
    comment = workout.comments.new(text: params.dig(:comment, :text), user: current_user)

    if comment.save
      redirect_to workout_path(workout, anchor: "comentarios"), notice: "Comentario publicado.", status: :see_other
    else
      redirect_to workout_path(workout, anchor: "comentarios"), alert: "Escribe tu comentario antes de publicarlo.", status: :see_other
    end
  end
end
