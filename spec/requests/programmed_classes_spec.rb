require 'rails_helper'

RSpec.describe "ProgrammedClasses", type: :request do
  let(:user) { create(:user) }

  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end

  let(:schedule) { create(:schedule, start_time: 2.days.from_now) }

  describe "POST /programmed_classes" do
    context "when not authenticated" do
      it "redirects to sign in" do
        post programmed_classes_path(schedule_id: schedule.id)
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "when authenticated" do
      before { sign_in(user) }

      it "creates a programmed class" do
        expect {
          post programmed_classes_path(schedule_id: schedule.id)
        }.to change { user.programmed_classes.count }.by(1)
      end

      it "sets status to programmed" do
        post programmed_classes_path(schedule_id: schedule.id)
        expect(user.programmed_classes.last).to be_programmed
      end

      it "redirects back" do
        post programmed_classes_path(schedule_id: schedule.id)
        expect(response).to redirect_to(schedules_url)
      end

      context "when already programmed" do
        let!(:pc) { create(:programmed_class, schedule: schedule, user: user) }

        it "cancels the programmed class" do
          post programmed_classes_path(schedule_id: schedule.id)
          expect(pc.reload).to be_canceled
        end
      end
    end
  end

  describe "DELETE /programmed_classes/:id" do
    let!(:pc) { create(:programmed_class, schedule: schedule, user: user) }

    context "when not authenticated" do
      it "redirects to sign in" do
        delete programmed_class_path(pc)
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "when authenticated" do
      before { sign_in(user) }

      it "sets status to canceled" do
        delete programmed_class_path(pc)
        expect(pc.reload).to be_canceled
      end
    end
  end

  describe "GET /programmed_classes" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get programmed_classes_path
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "when authenticated" do
      before { sign_in(user) }

      it "returns http success" do
        get programmed_classes_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
