require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "acceso según subscription_ends_at" do
    assert users(:member).active?
    assert_not users(:guest).active?
    assert_includes User.with_access, users(:member)
    assert_includes User.without_access, users(:guest)
    assert_includes User.without_access, users(:admin)
  end

  test "las admins pueden ver las clases sin suscripción" do
    assert users(:admin).can_watch?
    assert users(:member).can_watch?
    assert_not users(:guest).can_watch?
  end
end
