function score
% compute the lower bound of the Wilson score confidence interval, and plot it
% on a contour

n_max = 20;
p = 0.95;

% compute the number of ratings at each coordinate
for j = 1:n_max+1
   pos(j,:) = (0:n_max);
   pos(j+n_max,:) = (0:n_max); % this actually repeats a line; no matter
   neg(:,j) = (0:2*n_max)';
end

num = pos .+ neg;
phat = pos ./ num;

% compute the score
z = ( sqrt(2) * erfinv(p) ) .* ones(n_max*2+1,n_max+1);

score = ( phat + z.^2./2./num ...
      + z .* sqrt( ( phat.*(1-phat) + z.^2./4./num ) ./ num ) ) ...
   ./ ( 1 + z.^2./num );

% plot the graph
make_plot
contour( num, pos, abs( score ), 0.1:0.1:1 )
 % plot( [ 0 20 ], [ 0 20 ], 'k' )

colorbar( 'EastOutside' )
xlabel( 'positive' )
ylabel( 'negative' )
xlim( [ 0 40 ] )
ylim( [ 0 20 ] )

print -depsc 'wilson-score.eps' 
