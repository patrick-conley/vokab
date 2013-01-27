function score
% compute the lower bound of the Wilson score confidence interval, and plot it
% on a contour

n_max = 20;
p = 0.95;

% compute the number of ratings at each coordinate
for j = 1:n_max+1
   neg(j,:) = (0:n_max);
   neg(j+n_max,:) = (0:n_max); % this actually repeats a line; no matter
   pos(:,j) = (0:2*n_max)';
end

num = pos .+ neg;
phat = neg ./ num;

% compute the score
z = ( sqrt(2) * erfinv(p) ) .* ones(n_max*2+1,n_max+1);

score = ( phat + z.^2./2./num ...
      + z .* sqrt( ( phat.*(1-phat) + z.^2./4./num ) ./ num ) ) ...
   ./ ( 1 + z.^2./num );

% plot the graph
make_plot
contour( pos, neg, abs( score ), 0.1:0.1:0.9 )

xlim( [ 0 n_max ] )
ylim( [ 0 n_max ] )

colorbar( 'EastOutside' )
xlabel( 'positive ratings' )
ylabel( 'negative ratings' )
title( 'Wilson score' )

print -dpng 'wilson-score.png' 
