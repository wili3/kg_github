require 'io/console'
require 'net/http'
require 'uri'
require 'json'
require 'pry'
require 'base64'
require 'aws-sdk'
require 'etc'
require 'octokit'
require 'yaml'
# Get creds from file uploaderconfig 

$config = nil

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def main_interface 
	return true ? $res == '1' : false
end

def ask_title
	"Issue title?\n"
end

def ask_platform
	"Which platform?\n"
end

def ask_blocker
	"Blocked reasons:\n"
end

def ask_description
	"Type description:\n"
end

def interface_manager
	puts colorize("What do you want to do!", 32)
	puts colorize("(1) Create", 32)
	puts colorize("(2) Delete", 32)
	puts colorize("(3) Edit", 32)

	answer = gets.chomp
	answer
end

def delete_wip
	puts 'Choose index number: '
	index = gets.chomp

	$config.delete($hash[index.to_i - 1])

	File.open('data.yml','w') do |h| 
		h.write $config.to_yaml
	end
end

def edit_wip
	puts 'Choose index number: '
	index = gets.chomp

	puts ask_title
	title = gets.chomp

	puts ask_platform
	platform = gets.chomp

	puts ask_blocker
	blocked_by = gets.chomp

	puts ask_description
	description = gets.chomp

	binding.pry

	$config[$hash[index.to_i - 1]] = {:platform => platform, :blocked_by => blocked_by, :description => description}

	File.open('data.yml','w') do |h| 
		h.write $config.to_yaml
	end
end

def write_wip
	puts ask_title
	title = gets.chomp
	
	puts ask_platform
	platform = gets.chomp
	
	puts ask_blocker
	blocked_by = gets.chomp
	
	puts ask_description
	description = gets.chomp

	#$config = YAML.load_file('data.yml')

	$config[title] = {:platform => platform, :blocked_by => blocked_by, :description => description}
	File.open('data.yml','w') do |h| 
		h.write $config.to_yaml
	end
end

def print_wip
	index = 1;
	$hash.each do |h|
		puts colorize(index.to_s, 32) + ' => ' + colorize(h, 32) 
		puts colorize("\tPlatform: ", 32) + colorize($config[h][:platform], 31)
		puts colorize("\tBlocked by: ", 32) + colorize($config[h][:blocked_by], 31)
		puts colorize("\tDescription: ", 32) + colorize($config[h][:description], 28)
		index += 1
	end
end

def load_wip
	$config = YAML.load_file('data.yml')
	$hash = []
	$config.each{|c| $hash.push(c.first)}
	print_wip
end

def self.get_image (param)
	filepath = Etc.getpwuid.dir + '/'
	puts 'Do you want to add an image?'
	img_res = gets.chomp

	img_res = img_res.split('+')
	upload_multiple_files = false
	num_of_uploads = 0

	if img_res.count > 1
		num_of_uploads = img_res.last.to_i
	elsif img_res.count == 1
		num_of_uploads = 1
	end

	img_res = img_res.first

	obj_urls = []
	case img_res 
	when 'y' 
		num_of_uploads.times do
			puts 'write the name/path of the image'
			add_to_path = gets.chomp

			string_to_split = File.readlines("uploadfolder")
			string_to_split = string_to_split.first.split('|')
			image_folder_path = string_to_split.first
			bucket_name = string_to_split.last
			bucket_name = bucket_name.split("\n").first
			folder_path = image_folder_path + '/'

			#conditions to know if we are dragging an image or if we are typping the image name

			splitted_path = add_to_path.split('/')
			has_loaded_image = false
			index = 0
			temp_add_to_path = ""

			if  splitted_path.count <= 2 # Prepare the add_to_path
				if splitted_path.count == 1
					begin
						case index
						when 0
							has_loaded_image = File.exist?(filepath + add_to_path)
						when 1
							temp_add_to_path = folder_path + add_to_path
							has_loaded_image = File.exist?(filepath + temp_add_to_path)
						when 2
							temp_add_to_path = folder_path + add_to_path + '.png'
							has_loaded_image = File.exist?(filepath + temp_add_to_path)
						when 3
							temp_add_to_path = folder_path + add_to_path + '.jpg'
							has_loaded_image = File.exist?(filepath + temp_add_to_path)
						when 4
							return 
						end

						index +=1
					end while has_loaded_image == false
					add_to_path = temp_add_to_path
				elsif splitted_path.count == 2
					begin
						case index
						when 0
							has_loaded_image = File.exist?(filepath + add_to_path)
						when 1
							temp_add_to_path = add_to_path + '.png'
							has_loaded_image = File.exist?(filepath + temp_add_to_path)
						when 2
							temp_add_to_path = add_to_path + '.jpg'
							has_loaded_image = File.exist?(filepath + temp_add_to_path)
						when 3
							return 
						end

						index +=1
					end while has_loaded_image == false
					add_to_path = temp_add_to_path
				end
				filepath = filepath + add_to_path # Add the prepared add_to_path
			elsif splitted_path.count > 2
				split_space = add_to_path.split(' ') ### CAN'T DRAG AN IMAGE WITH SPACE BECAUSE OF THIS
				def_array = []
				split_space.each{|s| def_array << s.split("\\").first}
				i = 0
				def_fucking_string = ""

				def_array.count.times do
					if i == 0
						def_fucking_string = def_array[i]
					elsif i > 0
						def_fucking_string = def_fucking_string + ' ' + def_array[i]
					end
					i+=1
				end
			
				filepath = def_fucking_string
			end

			image = File.open(filepath)

			#begin AWS 
		
			Aws.config.update({
			  region: 'eu-west-1',
			  credentials: Aws::Credentials.new($aws_key, $aws_secret),
			})

			s3 = Aws::S3::Resource.new(region: 'eu-west-1')

			splitted_name = filepath.split('/').last
			obj = s3.bucket(bucket_name).object(splitted_name)
			uploaded_object = obj.upload_file(image , {content_type: "image/png",acl: "public-read"})
			obj_urls.push(obj.public_url)
			#end AWS
		end

		img_struct_1 = '![image]('
		img_struct_2 = ')  '
		def_img_string = ""
		
		obj_urls.each do |o|
			def_img_string = def_img_string + img_struct_1 + o + img_struct_2
		end

		puts "type the text:"
		$params_to_push['body'] = gets.chomp + def_img_string 
	when 'n'
		
		puts 'OK , enter the text:'
		$params_to_push['body'] = gets.chomp
	end
end

############ BEGIN 


can_init = false
can_init = File.exist?('uploaderconfig')

has_images_path = false
has_images_path = File.exist?('uploadfolder')

puts 'Working(1) or Reporting(2)?'
$res = gets.chomp

if main_interface == false
	if can_init && has_images_path 

		f = File.readlines('uploaderconfig')

		git_creds = f.first.split('-').first.split('>').last
		aws_creds = f.first.split('-').last.split('>').last

		git_user = git_creds.split(',').first
		git_token = git_creds.split(',').last

		$aws_key = aws_creds.split(',').first
		$aws_secret = aws_creds.split(',').last.split("\n").first

		#Initializes the required params

		param_names = ["title", "body", "labels"]
		$params_to_push = Hash.new

		labels = []

		keep_adding_labels = true
		will_open_url_at_the_end = false

		#Take input from user

		puts "Owner name:           1.web 2.ios 3.android 4.test"
		owner_name = gets.chomp

		case owner_name
		when '1'
			owner_name = 'keradgames'
			repo_name = 'goldenmanager.com'
		when '2'
			owner_name = 'keradgames'
			repo_name = 'goldenmanager-ios'
		when '3'
			owner_name = 'keradgames'
			repo_name = 'goldenmanager-android'
		when '4'
			owner_name = 'wili3'
			repo_name = 'test-repo'
		when '5'
			owner_name = 'wili3'
			repo_name = 'kg_github'
		end

		puts "What repo?" if repo_name == nil
		repo_name = gets.chomp if repo_name == nil 

		puts 'Issue reporting (1) or  PR comment (2)'
		issue_case = true ? gets.chomp == '1' : false
		
		if issue_case
			param_names.each do |param| 
				puts "#{param.capitalize}: "

				case param
				when 'title'
					$params_to_push[param] = gets.chomp
				when 'body'
					get_image(issue_case)
				when 'labels'
					labels =[]

					while keep_adding_labels do
						puts "Type the label name:             mu: 1.Bug 2.Must 3.Should 4.Could"
						label_to_add = gets.chomp
						labels << label_to_add 
						
						if label_to_add != ""
							puts "Do you want to add another label? "
							temp_ans = gets.chomp
							keep_adding_labels = false if temp_ans != 'y'
						elsif label_to_add == ""
							labels = []
							keep_adding_labels = false
						end
					end

					will_open_url_at_the_end = true if temp_ans == 'no'

					$params_to_push[param] = labels
				end
			end
			valid_uri = 'https://api.github.com/repos/' + owner_name + '/' + repo_name + '/' + 'issues'
			uri = URI(valid_uri)

			# Initialize the request and set the required data

			req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' => 'application/json'})
			req.body = $params_to_push.to_json
			req.basic_auth git_user, git_token

			# Starts the request

			res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
			    http.request(req)
			}

			# Prints the body
			uploaded_issue = JSON.parse(res.body)
			%x(open #{uploaded_issue.first(5).last.last}) if will_open_url_at_the_end == true

			puts res.body if will_open_url_at_the_end == true
		end

		if !issue_case
			valid_uri = 'https://api.github.com/repos/' + owner_name + '/' + repo_name + '/' + 'pulls'
			uri = URI(valid_uri)

			# Initialize the request and set the required data

			req = Net::HTTP::Get.new(uri, initheader = {'Content-Type' => 'application/json'})
			#req.body = $params_to_push.to_json
			req.basic_auth git_user, git_token

			# Starts the request

			res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
			    http.request(req)
			}

			obj = JSON.parse(res.body)
			pulls = []
			titles = []
			index = 0
			
			obj.each.select{|h| pulls.push(h['url']); titles.push(h['title'])}
			titles.each.select{|t| print t + ' => '; puts index + 1; index += 1}
			puts 'choose index of the pr you want to comment:'
			index_comment = gets.chomp.to_i - 1
			#puts JSON.parse(res.body)

			get_image (issue_case)
			
			client = Octokit::Client.new :access_token => git_token
			client.add_comment(owner_name + '/' + repo_name, pulls[index_comment].split('/').last.to_i, $params_to_push['body'])
		end
	end
else
	# write_wip
	load_wip
	ans = interface_manager
	
	case ans
	when '1'
		write_wip
	when '2'
		delete_wip
	when '3'
		edit_wip
	end

	load_wip
end


###################################################  END

if !can_init || !has_images_path
	puts 'Not able to begin without uploaderconfig file, please run \'bundle exec ruby setup.rb\' to make the setup configuration.'
end