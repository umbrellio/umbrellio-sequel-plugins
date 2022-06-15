# frozen_string_literal: true

DB.create_table :lock_test_model do
  primary_key :id
  column :count, :integer, default: 0
end

LockModel = Sequel::Model(:lock_test_model)

RSpec.describe "with_lock" do
  let!(:model) { LockModel.create(count: 0) }

  def locks_count
    DB[:pg_locks]
      .join(:pg_stat_activity, Sequel[:pg_locks][:pid] =~ Sequel[:pg_stat_activity][:pid])
      .where(mode: "RowShareLock")
      .where(Sequel[:query] =~ /lock_test_model/) # rubocop:disable Performance/StringInclude
      .count
  end

  it "updates the field" do
    count_before = locks_count
    expect(model).to receive(:lock!).with("FOR NO KEY UPDATE").once.and_call_original

    model.with_lock do
      expect(locks_count).to eq(count_before + 2)
      model.update(count: 1)
    end

    expect(locks_count).to eq(count_before)
    expect(model.count).to eq(1)
  end

  context "with another lock mode" do
    it "calls #lock! with specified mode" do
      expect(model).to receive(:lock!).with("FOR UPDATE").once
      model.with_lock("FOR UPDATE") { nil }
    end
  end

  describe "field when error occurs" do
    context "with outer transaction" do
      def update_model!
        DB.transaction do
          begin
            model.with_lock(savepoint: savepoint) do
              model.update(count: 1)
              raise
            end
          rescue
          end
        end
      end

      subject(:field) { model.reload.count }

      context "with savepoint" do
        let(:savepoint) { true }

        it "rollbacks changes" do
          update_model!
          expect(field).to eq(0)
        end
      end

      context "without savepoint" do
        let(:savepoint) { false }

        it "doesn't rollback changes" do
          update_model!
          expect(field).to eq(1)
        end
      end
    end
  end
end
