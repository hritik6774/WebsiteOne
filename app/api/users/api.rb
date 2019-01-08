module Users
  class API < Grape::API
    version 'v1', using: :path, vendor: 'agileventures'
    format :json
    prefix :api

    helpers do
      def current_user
        @current_user ||= User.authorize!(env)
      end

      def authenticate!
        error!('401 Unauthorized', 401) unless current_user
      end

      def ordered_users 
        User.where.not(id: -1).includes(:karma, :titles)
        .order("karmas.total DESC")
        .limit(100)
      end

      def contributions(user) 
        user.commit_counts.select do |commit_count|
          commit_count.user.following? commit_count.project
        end
      end

      def videos(user) 
        EventInstance.where(user_id: user.id)
                     .order(created_at: :desc)
                     .limit(5)
      end
    end

    resource :users do
      desc 'Return all users'
      get '/' do
        users_karma_total_hash = {}
        users_gravatar_url_hash = {}
        users_titles_hash = {}
        users_bio_hash = {}
        users_skill_list_hash = {}
        users_projects_list_hash = {}
        users_contributions_hash = {}
        users_contributions_total_hash = {}
        users_videos_hash = {}
        users_hangouts_hosted_hash = {}
        users_authentications_hash = {}
        users_profile_completeness_hash = {}
        users_membership_length_hash = {}
        users_activity_hash = {}

        User.includes(:karma, :titles).order("karmas.total DESC").limit(100).each do |user|
          users_karma_total_hash.merge!("#{user.id}": user.karma_total)
          users_gravatar_url_hash.merge!("#{user.id}": user.gravatar_url(size: 250))
          users_titles_hash.merge!("#{user.id}": user.titles.pluck(:name))
          users_bio_hash.merge!("#{user.id}": user.bio)
          users_skill_list_hash.merge!("#{user.id}": user.skill_list)
          users_projects_list_hash.merge!("#{user.id}": user.following_projects)
          users_contributions_hash.merge!("#{user.id}": contributions(user))
          users_contributions_total_hash.merge!("#{user.id}": user.commit_count_total)
          users_videos_hash.merge!("#{user.id}": videos(user))
          users_hangouts_hosted_hash.merge!("#{user.id}": user.number_hangouts_started_with_more_than_one_participant)
          users_authentications_hash.merge!("#{user.id}": user.authentications.count)
          users_profile_completeness_hash.merge!("#{user.id}": user.profile_completeness)
          users_membership_length_hash.merge!("#{user.id}": user.membership_length)
          users_activity_hash.merge!("#{user.id}": user.activity)
        end
        { 
          users: ordered_users, karma_total: users_karma_total_hash, gravatar_url: users_gravatar_url_hash, 
          users_title: users_titles_hash, users_bio: users_bio_hash, users_skills: users_skill_list_hash, 
          users_projects: users_projects_list_hash, users_contributions: users_contributions_hash, users_videos: users_videos_hash,
          users_commit_count_total: users_contributions_total_hash, users_hangouts: users_hangouts_hosted_hash, 
          users_authentications: users_authentications_hash, users_profile: users_profile_completeness_hash, users_membership_length: users_membership_length_hash,
          users_activity: users_activity_hash
        }
      end
    end
  end
end