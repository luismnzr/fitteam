class Workout < ApplicationRecord
    has_one_attached :cover
    has_many :comments
end
