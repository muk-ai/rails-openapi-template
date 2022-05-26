# == Schema Information
#
# Table name: tasks
#
#  id          :bigint           not null, primary key
#  description :string           not null
#  completed   :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe Task, type: :model do
  describe '#valid?' do
    context 'when description is empty' do
      subject { build(:task) }
      it 'is not valid' do
        expect(subject).not_to be_valid
      end
    end
  end
end
