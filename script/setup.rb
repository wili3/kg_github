require 'io/console'
require 'pry'
require 'etc'


user_directory = Etc.getpwuid.dir

route = "alias uploadissue=\"cd #{user_directory}/github_issues_uploader/script && bundle exec ruby githubuploader.rb\"\n"
has_alias = false

path = "#{user_directory}/.bash_profile"
file_lines = File.readlines(path)

file_lines.each do |f| #while has_alias == false
	if f == route
		has_alias = true
		break
	else
		puts 'not equal'
	end
end

binding.pry



puts 'specify the folder where your images you want to upload are placed i.e: Downloads'
img_directory = gets.chomp

puts 'bucket name: '
bucket_name = gets.chomp

puts 'enter github username/mail: '
git_user = gets.chomp

puts 'enter github token: '
git_token = gets.chomp

puts 'enter aws access key: '
aws_access = gets.chomp

puts 'enter aws secret key'
aws_secret = gets.chomp

binding.pry

git_header = 'githubcredentials>'
aws_header = 'awscredentials>'

def_string = git_header + git_user + ',' + git_token + '-' + aws_access + ',' + aws_secret

fname = 'uploaderconfig'
file = File.open(fname,'w')
file.puts def_string
file.close

def_string_bucket = img_directory + '|' + bucket_name

fname = 'uploadfolder'
file_2 = File.open(fname,'w')
file_2.puts def_string_bucket
file_2.close