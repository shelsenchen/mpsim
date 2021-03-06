function J = get_jacobian_local2cart_viageod (pt_local, base_geod, ell, ...
optimize)
%GET_JACOBIAN_LOCAL2CART_VIAGEOD: Return the Jacobian matrix of global Cartesian coordinates w.r.t. local Cartesian coordinates (via geodetic coordinates).

    if (nargin < 4),  optimize = true;  end

    num_pts   = size(pt_local, 1);
    num_bases = size(base_geod, 1);
    myassert (num_bases == 1 || num_bases == num_pts);

    if optimize && nnz(pt_local) == 0
        J = get_jacobian_local2cart (base_geod, ell);
        if (num_bases == 1),  J = repmat(J, [1, 1, num_pts]);  end
        return;
    end
    
    pt_geod = convert_from_local_cart_viageod (pt_local, base_geod, ell);
    J_local2geod = get_jacobian_local2geod_viageod (base_geod, ell);
    J_geod2cart  = get_jacobian_geod2cart (pt_geod, ell);
    %J_geod2cart = get_jacobian_geod2cart (base_geod, ell);  % WRONG!!!

    J = frontal_mtimes(J_geod2cart, J_local2geod);
end

%!shared
%! %rand('seed', 0)
%! n = 1;
%! ell = get_ellipsoid('grs80');
%! base_geod = rand_pt_geod (1);
%! pt_local = 1e6*rand(n,3);  % use very large local coord because for small local coord even wrong implementation works.

%!test
%! % compare analytical to numerical derivatives:
%! function pt_cart = func (pt_local, base_geod, ell)
%!     [pt_geod, pt_cart] = convert_from_local_cart_viageod (pt_local, base_geod, ell);
%! end
%! f = @(pt_local_) func (pt_local_, base_geod, ell);
%! J = diff_func_obs (f, pt_local);
%! J2 = get_jacobian_local2cart_viageod (pt_local, base_geod, ell);
%! 
%! e = J - J2;
%! tol = 2*100*nthroot(eps(J), 3);  tol(tol<eps) = eps;
%! %J, J2
%! %[e(:), tol(:), abs(e(:)) < tol(:)]
%! myassert (J2, J, -tol);

%!test
%! % Test multiple points
%! n = 4;
%! J = get_jacobian_local2cart_viageod (repmat(pt_local(1,:), n, 1), base_geod, ell);
%! myassert (size(J), [3,3,n]);
%! %J - repmat(J(:,:,1), [1, 1, n])
%! myassert (J, repmat(J(:,:,1), [1, 1, n]));

%!test
%! % consistency check:
%! J = get_jacobian_local2cart_viageod (pt_local, base_geod, ell);
%! J_inv = get_jacobian_cart2local_viageod (pt_local, base_geod, ell);
%! I = J * J_inv;
%! %I - eye(3)
%! myassert (I, eye(3), -sqrt(eps))

%!test
%! % test optimization for greater speed:
%! n = ceil(1000*rand);
%! ell = get_ellipsoid('grs80');
%! base_geod = rand_pt_geod;
%! pt_local = zeros(n, 3);
%! 
%! % make sure functions are loaded in memory:
%! get_jacobian_local2cart_viageod (pt_local, base_geod, ell);
%! 
%! t = cputime; J1 = get_jacobian_local2cart_viageod (pt_local, base_geod, ell, true); t1 = cputime - t;
%! t = cputime; J2 = get_jacobian_local2cart_viageod (pt_local, base_geod, ell, false); t2 = cputime - t;
%! 
%! %J1, J2
%! myassert (J1, J2, -sqrt(eps));
%! 
%! % cputime_res applies to either t1 or t2 individually; tol applies to t2-t1;
%! tol = 2*cputime_res + sqrt(eps);
%! %[t1, t2+tol]
%! myassert (t1 <= (t2 + tol));

