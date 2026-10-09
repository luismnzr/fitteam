module Admin
  # Bandeja de comentarios de las usuarias en los workouts. Las respuestas se
  # guardan como comentario hijo (parent_id) y en el sitio salen como
  # "Ana Gaby respondió".
  class CommentsController < BaseController
    def index
      @status = params[:status].presence_in(%w[unanswered all]) || "unanswered"
      scope = @status == "unanswered" ? Comment.unanswered : Comment.roots
      if params[:workout_id].present?
        @workout = Workout.find_by(id: params[:workout_id])
        scope = scope.where(workout_id: params[:workout_id])
      end
      @comments = scope.includes(:user, :workout, :replies).order(created_at: :desc).page(params[:page]).per(20)
      @unanswered_count = Comment.unanswered.count
    end

    def reply
      comment = Comment.roots.find(params[:id])
      reply = comment.replies.new(workout: comment.workout, user: current_user, text: params.dig(:reply, :text))
      if reply.save
        redirect_back fallback_location: admin_comments_path, notice: "Respuesta publicada en \"#{comment.workout&.title}\"."
      else
        redirect_back fallback_location: admin_comments_path, alert: "Escribe una respuesta antes de enviarla."
      end
    end

    def destroy
      Comment.find(params[:id]).destroy
      redirect_back fallback_location: admin_comments_path, notice: "Comentario eliminado.", status: :see_other
    end
  end
end
