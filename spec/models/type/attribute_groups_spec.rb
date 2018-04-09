#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::Type, type: :model do
  let(:type) { FactoryGirl.build(:type) }

  before do
    # Clear up the request store cache for all_work_package_attributes
    RequestStore.clear!
  end

  describe "#attribute_groups" do
    shared_examples_for 'appends the children query' do |position|
      it "at position #{position}" do
        group = type.attribute_groups[position]

        expect(group.key).to eql :children
        query = group.members[0]

        expect(query.class).to eql Query

        expect(query.filters.length).to eql(1)

        filter = query.filters[0]

        expect(filter.name).to eql(:parent)

        expect(query.column_names).to eql(%i(id type subject))
        expect(query.show_hierarchies).to be_falsey
      end
    end

    shared_examples_for 'returns default attributes' do
      it do
        expect(type.read_attribute(:attribute_groups)).to be_empty

        attribute_groups = type.attribute_groups[0..2].map do |group|
          [group.key, group.attributes]
        end
        expect(attribute_groups).to eql type.default_attribute_groups
      end

      it_behaves_like 'appends the children query', 3
    end

    context 'with attributes provided' do
      before do
        type.attribute_groups = [['foo', []], ['bar', %w(blubs date)]]
      end

      it 'removes unknown attributes from a group' do
        group = type.attribute_groups[1]

        expect(group.key).to eql 'bar'
        expect(group.members).to eql ['date']
      end

      it 'keeps groups without attributes' do
        group = type.attribute_groups[0]

        expect(group.key).to eql 'foo'
        expect(group.members).to eql []
      end

      it_behaves_like 'appends the children query', 2
    end

    context 'with empty attributes provided' do
      before do
        type.attribute_groups = []
      end

      it_behaves_like 'returns default attributes'
    end

    context 'with no attributes provided' do
      it_behaves_like 'returns default attributes'
    end
  end

  describe '#default_attribute_groups' do
    subject { type.default_attribute_groups }

    it 'returns an array' do
      expect(subject.any?).to be_truthy
    end

    it 'each attribute group is an array' do
      expect(subject.detect { |g| g.class != Array }).to be_falsey
    end

    it "each attribute group's 1st element is a String (the group name) or symbol (for i18n)" do
      expect(subject.detect { |g| g.first.class != String && g.first.class != Symbol }).to be_falsey
    end

    it "each attribute group's 2nd element is an Array (the group members)" do
      expect(subject.detect { |g| g.second.class != Array }).to be_falsey
    end

    it 'does not return empty groups' do
      # For instance, the `type` factory instance does not have custom fields.
      # Thus the `other` group shall not be returned.
      expect(subject.detect do |attribute_group|
        group_members = attribute_group[1]
        group_members.nil? || group_members.size.zero?
      end).to be_falsey
    end
  end

  describe "#validate_attribute_groups" do
    it 'raises an exception for invalid structure' do
      # Exampel for invalid structure:
      type.attribute_groups = ['foo']
      expect { type.save }.to raise_exception(NoMethodError)
      # Exampel for invalid structure:
      type.attribute_groups = [[]]
      expect { type.save }.to raise_exception(NoMethodError)
      # Exampel for invalid group name:
      type.attribute_groups = [['', ['date']]]
      expect(type).not_to be_valid
    end

    it 'fails for duplicate group names' do
      type.attribute_groups = [['foo', ['date']], ['foo', ['date']]]
      expect(type).not_to be_valid
    end

    it 'passes validations for known attributes' do
      type.attribute_groups = [['foo', ['date']]]
      expect(type.save).to be_truthy
    end

    it 'passes validation for defaults' do
      expect(type.save).to be_truthy
    end

    it 'passes validation for reset' do
      # A reset is to save an empty Array
      type.attribute_groups = []
      expect(type).to be_valid
    end
  end

  describe 'custom fields' do
    let!(:custom_field) do
      FactoryGirl.create(
        :work_package_custom_field,
        field_format: 'string'
      )
    end
    let(:cf_identifier) do
      :"custom_field_#{custom_field.id}"
    end

    it 'can be put into attribute groups' do
      # Enforce fresh lookup of groups
      OpenProject::Cache.clear

      # Can be enabled
      type.attribute_groups = [['foo', [cf_identifier.to_s]]]
      expect(type.save).to be_truthy
      expect(type.read_attribute(:attribute_groups)).not_to be_empty
    end
  end
end
