require 'fireap/data/member'
require 'fireap/util/consul'

module Fireap::Model
  class Member
    attr :name, :addr, :port, :tags, :status, :status_name, :protocol_min
    attr :protocol_max, :protocol_cur, :delegate_min, :delegate_max, :delegate_cur

    def initialize(stash)
      stash.each do |key, val|
        if key == 'status'
          @status_name = Fireap::Util::Consul.member_status_code2name(val)
        end
        instance_variable_set("@#{key}", val)
      end
    end

    def self.select(status: nil, as: :array)
      data = Fireap::Data::Member.get_all
      return nil unless data

      list  = []
      stash = {}
      data.each do |dat|
        member = Fireap::Data::Member.new(dat).to_model
        if status and status != member.status_name
          next
        end
        if as == :hash
          stash[member.name] = member
        else
          list.push(member)
        end
      end

      return stash if as == :hash
      list
    end
  end
end
