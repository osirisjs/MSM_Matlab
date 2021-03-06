function se = RES_BMSM_2stage_std_err(data,para,kbar,n)
    % INPUTS:
    %    DATA                -   2 columns (or row) of mean zero data
    %    KBAR                -   The number of volatility components.
    %    n                   -   The number of trading periods in 1 year. E.g
    %                            n= 252 for the number of business days in a year. n=12 for monthly data.
    %    para                -   A 1-by-8 row vector of parameters 
    %                            [m01, m02, sigma1, sigma2, gamma_kbar, b, rho_e, lambda]
    % OUTPUTS:
    %    se                -     A 8x1 row vector of standard errors for parameters 
    %                            [m01, m02, sigma1, sigma2, gamma_kbar, b, rho_e, lambda]
    
    %Note that the hassian matrix for the 2 stage bivariate MSM is a block
    %diagonal matrix 8-by-8 of [H1 0_2]
    %                          [0_6 H2], where H1 is a 6-by-6 matrix, H2 is
    %                          a 2-by-2 matrix, 0_2 is a 6-by-2 matrix and
    %                          0_6 is a 2-by-6 matrix. Therefor, the
    %                          standard errors for the first 6 parameters
    %                          [m01, m02, sigma1, sigma2, gamma_kbar, b] are estimated separately and 
    %                          the standard errors for the last 2
    %                          parameters [rho_e, lambda] are also estimated separately.
    %References:  Volatility comovement: a multifrequency approach. 
    %             Journal of Econometrics, 131(1-2):179{215.
    % ------------------------------------------------------------------------- 
    
    %Checks:
    if size(data,2) > 2
        data = data';
    end
    if size(data,1) == 1
        error('data series must be a matrix T-by-2')
    elseif isempty(data)
        error('data is empty')
    end
    
    if size(para,2) > 1
        para=para';
    end
    if size(para,1) == 1 ||size(para,1)>8
        error('para must be a 8-by-1 vector')
    end
    
    if (kbar < 1) 
    error('k must be a positive integer')
    end
    kbar = floor(kbar);
    
    T=size(data,1);
    
    para1=para(1:6);
    para2=para(7:8);
    
    %Stage 1 parameter standard errors:
    A = zeros((2^kbar),(2^kbar));
    for i =0:2^kbar-1       
        for j = i:(2^kbar-1)-i  
            A(i+1,j+1) = bitxor(i,j);
        end
    end
    
    if kbar==1
        %Exclude b from the estimation of covariance matrix because b is not defined at k=1.
        %Else the standard errors for all the stage 1 parameters will be inaccurate or may even return Inf
        
        gt1       = MSM_grad(@BMSM_2stage_LLs1,para1,data,kbar,n,A);
        gt1       = gt1(:,1:5);
        J1        = gt1'*gt1;
        H1        = MSM_hessian(@BMSM_2stage_likelihood1,para1,kbar,data,A,n);
        H1        = H1(1:5,1:5);
        [~,I]     = chol(H1);
                    %if H1 (the negative of Hessian) is not positive-definite (this usually happens when m0 or gamma_k takes boundary values)
                    % use the Outer Product Gradient for standard errors.
        if I~=0
            se1   = sqrt(diag(inv(J1)));
        else
            se1   = sqrt(diag(inv(H1/T)*J1/T^2*inv(H1/T)));
        end
        se1       = [se1;nan];
    else
        gt1       = MSM_grad(@BMSM_2stage_LLs1,para1,data,kbar,n,A);
        J1        = gt1'*gt1;
        H1        = MSM_hessian(@BMSM_2stage_likelihood1,para1,kbar,data,A,n);
        [~,I]     = chol(H1);
        if I~=0
            se1   = sqrt(diag(inv(J1)));
        else
            se1   = sqrt(diag(inv(H1/T)*J1/T^2*inv(H1/T)));
        end
    end
       
    %Stage 2 parameter standard errors:
    gt2       = MSM_grad(@RES_BMSM_2stage_LLs2,para2,para1,data,kbar,n);
    J2        = gt2'*gt2;
    H2        = MSM_hessian(@RES_BMSM_2stage_likelihood2,para2,kbar,data,para1,n);
    [~,I]     = chol(H2);
    if I~=0
        se2   = sqrt(diag(inv(J2)));
    else
        se2   = sqrt(diag(inv(H2/T)*J2/T^2*inv(H2/T)));
    end
        
  
    se=[se1' se2'];
   
end
