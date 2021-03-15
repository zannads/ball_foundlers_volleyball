function out = extractfield_( s, name)
%EXTRACTFIELD_ This function extracts from an array of struct an array with
% only that requested field
if isempty( s)
    return;
end

% how many strcut are present in the array
col = size( s(1).(name), 2);
out = zeros( length( s ), col) ;

% save them
for idx = 1:length( s )
    out( idx, :) = s(idx).(name);
end
end