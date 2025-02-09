require "application_system_test_case"

class WorkoutsTest < ApplicationSystemTestCase
  setup do
    @workout = workouts(:one)
  end

  test "visiting the index" do
    visit workouts_url
    assert_selector "h1", text: "Workouts"
  end

  test "should create workout" do
    visit workouts_url
    click_on "New workout"

    fill_in "Category", with: @workout.category
    fill_in "Day", with: @workout.day
    fill_in "Duration", with: @workout.duration
    fill_in "Intensity", with: @workout.intensity
    fill_in "Material", with: @workout.material
    fill_in "Title", with: @workout.title
    fill_in "Video url", with: @workout.video_url
    click_on "Create Workout"

    assert_text "Workout was successfully created"
    click_on "Back"
  end

  test "should update Workout" do
    visit workout_url(@workout)
    click_on "Edit this workout", match: :first

    fill_in "Category", with: @workout.category
    fill_in "Day", with: @workout.day.to_s
    fill_in "Duration", with: @workout.duration
    fill_in "Intensity", with: @workout.intensity
    fill_in "Material", with: @workout.material
    fill_in "Title", with: @workout.title
    fill_in "Video url", with: @workout.video_url
    click_on "Update Workout"

    assert_text "Workout was successfully updated"
    click_on "Back"
  end

  test "should destroy Workout" do
    visit workout_url(@workout)
    click_on "Destroy this workout", match: :first

    assert_text "Workout was successfully destroyed"
  end
end
