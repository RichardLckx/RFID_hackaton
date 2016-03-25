filename = 'signal.txt';
e01 = importdata(filename);
plot(e01);
%sender data fields
send_threshold_y = 0.35;
sample_threshold_send = 1;

last_threshold_pass = 0;
bit_zero_lower_bound_x = 40;
bit_zero_upper_bound_x = 60;
bit_one_lower_bound_x = 70;
bit_one_upper_bound_x = 100;
RTcal_size_lower_bound_x = 145;
RTcal_size_upper_bound_x = 165;
RTcal_found = 0;
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

%calculate reader y treshold
y_min = 20;
y_max = 0;
for i = 1:1:length(e01)
    if(e01(i) < y_min)
        y_min = e01(i);
    end
    if(e01(i) > y_max)
        y_max = e01(i);
    end
end

send_threshold_y = ((y_min + y_max) / 2);
send_threshold_y;

%decode reader message
for i= 1:2650
	%below threshold
    if e01(i) < send_threshold_y					
        %initializing the last_threshold pass for the first passing to avoid false first data symbol
        if last_threshold_pass == 0 
			last_threshold_pass = i;		
        end
        
        %declining values, downward signal
        if ((e01(i-1) > e01(i)) && (e01(i-1) > send_threshold_y))				
			current_threshold_pass = i;
            
        %inclining values, upward signal
		elseif (e01(i+1) > e01(i) && (e01(i+1) > send_threshold_y))			
			current_threshold_pass = i+1;
        end
		
        %get the distance between the last two times y was below the
        %treshold?
		threshold_pass_diff = current_threshold_pass - last_threshold_pass;
		
        %Search the corresponding binairy value that belongs to this distance, 
        % gaurded by the upper and lower bounds
		if ((threshold_pass_diff < bit_zero_upper_bound_x) && (threshold_pass_diff > bit_zero_lower_bound_x) && (RTcal_found == 1))
			result_send = strcat(result_send, '0');
		elseif ((threshold_pass_diff < bit_one_upper_bound_x) && (threshold_pass_diff > bit_one_lower_bound_x) && (RTcal_found == 1))
			result_send = strcat(result_send, '1');
		elseif ((threshold_pass_diff < RTcal_size_upper_bound_x) && (threshold_pass_diff > RTcal_size_lower_bound_x))
			result_send = strcat(result_send,'d');
			RTcal_found = 1;
		end
		last_threshold_pass = current_threshold_pass;
	end
end

fprintf('Reader message: %s \n', result_send);

%decode tag message
for i= 2650:5000
    %passing the threshold
	if e01(i) < tag_threshold					
		if last_threshold_pass == 0
            %initializing the last_threshold pass for the first passing to avoid false first data symbol
			last_threshold_pass = i;		
        end
        
        %declining values, downward signal
		if ((e01(i-1) > e01(i)) && (e01(i-1) > tag_threshold))				
			current_threshold_pass = i;
        %inclining values, upward signal
		elseif (e01(i+1) > e01(i) && (e01(i+1) > tag_threshold))			
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
			%The value 0 before v misses a flank, but the zero is there so we add it here. (unique size of v)
            result_tag = strcat(result_tag, '0v');			
		elseif (((threshold_pass_diff/2) < tag_data_one_upper_bound) && ((threshold_pass_diff/2) > tag_data_one_lower_bound))
			%might a value 1v appear, we notice it if the flanks are twice the size of a normal 1
            result_tag = strcat(result_tag, '1v');			
		end 
		last_threshold_pass = current_threshold_pass;
	end
end

fprintf('Tag message: %s \n', result_tag);

