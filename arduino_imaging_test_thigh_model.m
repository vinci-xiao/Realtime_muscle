num_electrodes = 16;
state = 0;
origin_frame = zeros(num_electrodes*num_electrodes, 1);
old_frame = zeros(num_electrodes*num_electrodes, 1);
calc_colours('backgnd', [1,1,1]);

% imdl = mk_common_model('h2C',num_electrodes); % h2c j2c j2d4c
fmdl = mk_library_model('thigh_R_1x16');
options = {'no_meas_current', 'no_rotate_meas'};
%[stim, meas_select] = mk_stim_patterns(num_electrodes, 1, '{mono}', '{mono}', options, 1);
[stim, meas_select] = mk_stim_patterns(num_electrodes, 1, [0,1], [0,1], options, 10);
imdl.fwd_model.stimulation = stim;
imdl.fwd_model.meas_select = meas_select;
imdl.reconst_type = 'difference';

fmdl = mdl_normalize(fmdl, 0);
% [~,fmdl] = elec_rearrange([16,2],'square', fmdl);
 
img=mk_image(fmdl,1);
img.elem_data(fmdl.mat_idx{2})= 20; 
img.elem_data(fmdl.mat_idx{3})= 20; 
img.elem_data(fmdl.mat_idx{4})= 20; 
img.elem_data(fmdl.mat_idx{5})= 20; 
vh = fwd_solve(img);
 
show_fem(img, [0,1]);

fmdl.solve=      @fwd_solve_1st_order;
fmdl.system_mat= @system_mat_1st_order;
fmdl.jacobian=   @jacobian_adjoint;
fmdl.misc.perm_sym= '{n}';
fmThigh = eidors_obj('fwd_model', fmdl);
 
inv.name=  'EIT inverse: thigh';
inv.solve= @inv_solve_diff_GN_one_step;
inv.hyperparameter.value = 1e-2;
inv.jacobian_bkgnd.value= 1;
inv.RtR_prior= 'prior_laplace';
inv.reconst_type= 'difference';
inv.fwd_model= fmThigh;
inv= eidors_obj('inv_model', inv);


% img = mk_image(imdl, 2);
% vh = fwd_solve(img);

s = serialport("COM9", 115200); % 113451801 /dev/cu.SLAB_USBtoUART usbmodem112118501 usbserial-14510 594 23 106027301 112118501 usbmodem87006901
s.Timeout = 180;
fileID = fopen('sittttt7.txt','w');

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
            rec_img = inv_solve(inv, vh, frame);
            rec_img.calc_colours.ref_level = -1;

            data_1 = rec_img.elem_data(rec_img.fwd_model.mat_idx{2});
            data_2 = rec_img.elem_data(rec_img.fwd_model.mat_idx{3});
            % rec_img.calc_colours.clim = [1]; % play around with this number and pick one that fits the specific phantom & measuring objects
            show_fem(rec_img)
%             drawnow;
            
            old_frame = repmat(frame, 1);
        end
    end
end