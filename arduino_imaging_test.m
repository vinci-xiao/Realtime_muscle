num_electrodes = 16;
state = 0;
origin_frame = zeros(num_electrodes*num_electrodes, 1);
old_frame = zeros(num_electrodes*num_electrodes, 1);
s = serialport("COM9", 115200); % 113451801 /dev/cu.SLAB_USBtoUART usbmodem112118501 usbserial-14510 594 23 106027301 112118501 usbmodem87006901
s.Timeout = 180;

imdl = mk_common_model('h2C',num_electrodes); % h2c j2c j2d4c
options = {'no_meas_current', 'no_rotate_meas'};
%[stim, meas_select] = mk_stim_patterns(num_electrodes, 1, '{mono}', '{mono}', options, 1);
[stim, meas_select] = mk_stim_patterns(num_electrodes, 1, [0,1], [0,1], options, 10);
imdl.fwd_model.stimulation = stim;
imdl.fwd_model.meas_select = meas_select;
imdl.reconst_type = 'difference';

img = mk_image(imdl, 2);
vh = fwd_solve(img);

show_fem(img, [0,1]);

fileID = fopen('sittttt4.txt','w');

while true
    line = readline(s);
    %disp(line);
    
    if state == 0
        disp(line);
        fprintf(fileID, line);
        if strncmp(line, "origin frame", 12)
            % Read data
            for i = 1:(num_electrodes*num_electrodes)
                origin_frame(i) = str2double(readline(s));
%         comment out following line for origin frame alternative:
%         origin_frame(i) = 0.025;
            end

            state = 1;
            disp("origin set");
%             fprintf(fileID, 'origin frame\r\n');
            fprintf(fileID, '%.4f\r\n', origin_frame);
        end
    else
        if strncmp(line, "frame", 5)
            % Read data
            frame = zeros(num_electrodes*num_electrodes, 1);
            for i = 1:(num_electrodes*num_electrodes)
                frame(i) = str2double(readline(s));
            end
            fprintf(fileID, 'frame\r\n');
            fprintf(fileID, '%.4f\r\n', frame);
            
            %show_slices(inv_solve(imdl, old_frame, frame));
%             show_slices(inv_solve(imdl, origin_frame, frame));
%             show_slices(inv_solve(imdl, vh, frame));
            %rec_img = inv_solve(imdl, vh, frame);
            rec_img = inv_solve(imdl, vh, frame);
            rec_img.calc_colours.ref_level = 0;
            % rec_img.calc_colours.clim = [1]; % play around with this number and pick one that fits the specific phantom & measuring objects
            show_fem(rec_img)
%             drawnow;
            
            old_frame = repmat(frame, 1);
        end
    end
end