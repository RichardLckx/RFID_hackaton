filename = 'signal.txt';
e01 = importdata(filename);

%sender data fields
send_threshold = 0.35;
sample_threshold_send = 1;

last_threshold_pass = 0;
data_zero_lower_bound = 40;
data_zero_upper_bound = 60;
data_one_lower_bound = 70;
data_one_upper_bound = 100;
data_delimiter_lower_bound = 145;
data_delimiter_upper_bound = 165;
delim_found = 0;
result_send = '';

%tag response data fields
tag_threshold = 0.63;
tag_data_zero_lower_bound = 5;
tag_data_zero_upper_bound = 10;
tag_data_one_lower_bound = 15;
tag_data_one_upper_bound = 20;
tag_data_v_lower_bound = 20;
tag_data_v_upper_bound = 30;
detected_tag_zero = 0;
result_tag = '';

%message pre-ambles
% query_rep = '00';
% ack = '01';
% query = '1000';
% query_adjust = '1001';
% select = '1010';
% reserved = '1011';
% nack = '11000000';
% req_rn = '11000001';
% read = '11000010';
% write = '11000011';


for i= 1:2650
	if e01(i) < send_threshold					%passing the threshold
		if last_threshold_pass == 0 
			last_threshold_pass = i;		%initializing the last_threshold pass for the first passing to avoid false first data symbol
		end
		if ((e01(i-1) > e01(i)) && (e01(i-1) > send_threshold))				%declining values, downward signal
			current_threshold_pass = i;
		elseif (e01(i+1) > e01(i) && (e01(i+1) > send_threshold))			%inclining values, upward signal
			current_threshold_pass = i+1;
		end
		
		threshold_pass_diff = current_threshold_pass - last_threshold_pass;
		
		if ((threshold_pass_diff < data_zero_upper_bound) && (threshold_pass_diff > data_zero_lower_bound) && (delim_found == 1))
			result_send = strcat(result_send, '0');
		elseif ((threshold_pass_diff < data_one_upper_bound) && (threshold_pass_diff > data_one_lower_bound) && (delim_found == 1))
			result_send = strcat(result_send, '1');
		elseif ((threshold_pass_diff < data_delimiter_upper_bound) && (threshold_pass_diff > data_delimiter_lower_bound))
			result_send = strcat(result_send,'d');
			delim_found = 1;
		end
		last_threshold_pass = current_threshold_pass;
	end
end

fprintf('Sent message: %s \n', result_send);

for i= 2650:5000
	if e01(i) < tag_threshold					%passing the threshold
		if last_threshold_pass == 0 
			last_threshold_pass = i;		%initializing the last_threshold pass for the first passing to avoid false first data symbol
		end
		if ((e01(i-1) > e01(i)) && (e01(i-1) > tag_threshold))				%declining values, downward signal
			current_threshold_pass = i;
		elseif (e01(i+1) > e01(i) && (e01(i+1) > tag_threshold))			%inclining values, upward signal
			current_threshold_pass = i+1;
		end
		
		threshold_pass_diff = current_threshold_pass - last_threshold_pass;
		
		if ((threshold_pass_diff < tag_data_zero_upper_bound) && threshold_pass_diff > tag_data_zero_lower_bound)
			detected_tag_zero =  detected_tag_zero + 1;
			if(detected_tag_zero == 2)
				result_tag = strcat(result_tag, '0');
				detected_tag_zero = 0;
			end
		elseif ((threshold_pass_diff < tag_data_one_upper_bound) && (threshold_pass_diff > tag_data_one_lower_bound))
			result_tag = strcat(result_tag, '1');
		elseif ((threshold_pass_diff < tag_data_v_upper_bound) && (threshold_pass_diff > tag_data_v_lower_bound)) 
			result_tag = strcat(result_tag, '0v');			%The value 0 before v misses a flank, but the zero is there so we add it here. (unique size of v)
		elseif (((threshold_pass_diff/2) < tag_data_one_upper_bound) && ((threshold_pass_diff/2) > tag_data_one_lower_bound))
			result_tag = strcat(result_tag, '1v');			%might a value 1v appear, we notice it if the flanks are twice the size of a normal 1
		end 
		last_threshold_pass = current_threshold_pass;
	end
end

fprintf('Tag message: %s \n', result_tag);