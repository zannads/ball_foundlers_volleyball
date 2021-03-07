function out = extractfield_( s, name)
if isempty( s)
    return;
end

col = size( s(1).(name), 2);
out = zeros( length( s ), col) ;

for idx = 1:length( s )
    out( idx, :) = s(idx).(name);
end
end