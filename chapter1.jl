include("optics.jl");

#Create a disc pupil
# Because of the Fourier transform later on, we would like it to be in a double-sized support
pupil_disc = circular_aperture(256, 128, centered=true);

# Create an annulus pupil
pupil_annulus = circular_aperture(256, 128, centered=true)-circular_aperture(256, 64, centered=true);

# Orthogonality check of disc zernikes
nz=20;
npix = 256
zprod = zeros(nz,nz);
for i=1:nz
  for j=1:nz
    Zi = zernike(i, npix, npix, centered=true)
    Zj = zernike(j, npix, npix, centered=true)
    zprod[i,j]=sum(Zi.*Zj)
  end
end
imview(zprod, title="Zernike Orthogonality on Disc")
#If we want to check deeper, we can go in log plot, but we need to remove tiny <0 values e.g. -1e-12
zprod=zprod.*(abs(zprod).>1e-12)
imview(log.(zprod), title="Zernike Orthogonality on Disc -- Deep check")

# Orthogonality check of annuli zernikes
nz=20;
npix=256
pupil_annulus_2 = circular_aperture(npix, npix, centered=true)-circular_aperture(npix, npix/4, centered=true);
zprod_ann = zeros(nz,nz);
for i=1:nz
  for j=1:nz
    Zi = zernike(i, npix, npix, centered=true)
    Zj = zernike(j, npix, npix, centered=true)
    zprod_ann[i,j]=sum(Zi.*Zj.*pupil_annulus_2)
  end
end
imview(zprod_ann, title="Zernike Orthogonality on Annulus")

#Decomposition of a phase into Zernikes
using FITSIO
phase=read((FITS("atmosphere_d_r0_10.fits"))[1]);
imview(phase,title="Original phase");
npix_phase = (size(phase))[1]
nz = 50; #let's decompose into 20 modes
a = zeros(nz); # here is the array to store the decomposition factors
for i=1:nz
    Zi = zernike(i, npix_phase, npix_phase, centered=true)
    a[i]=sum(Zi.*phase)
end
println("Decomposition coefficients: ", a);
recomposed_phase = zeros(size(phase)) # array of zeros of the same size as the original phase
for i=1:nz
   recomposed_phase += a[i]*zernike(i, npix_phase, npix_phase, centered=true)
end
imview(recomposed_phase,title="Recomposed phase");


# GOLAY pupils

#Golay-3 sub-aperture positions
npix=256
centers_x=[-0.5,0.5,0]*npix/4
centers_y = [-sqrt(3)/6,-sqrt(3)/6,sqrt(3)/3]*npix/4

diam = 64 #sub-aperture diameter
aperture = zeros(npix,npix)
for i=1:length(centers_x)
 aperture += circular_aperture(npix, diam, (npix+1)/2+centers_x[i], (npix+1)/2+centers_y[i])
end
imview(aperture, title="Golay-3")

#Golay-6 sub-aperture positions
centers_x=[1,3/2,0,-1,-1,-1/2]*npix/4
centers_y=[2,-1,-4,-4,2,5]*sqrt(3)/6*npix/4

diam = 64 #sub-aperture diameter
aperture = zeros(npix,npix)
for i=1:length(centers_x)
 aperture += circular_aperture(npix, diam, (npix+1)/2+centers_x[i], (npix+1)/2+centers_y[i])
end
imview(aperture, title="Golay-6")

# Making a PSF
npix=4096;
aperture = circular_aperture(npix, npix/16, centered=true); # npix/2 because FFT needs padded pupil by a factor 2
aperture = aperture/sqrt(sum(aperture.^2));  # pupil normalization
#phase= zernike(4, npix, npix/2, centered=true);
phase = 0
pupil=aperture.*cis.(phase);
psf=abs2.(ifft(pupil)*npix); #the npix factor is for the normalization of the fft
psf = circshift(psf,(npix/2,npix/2)); # fft is centered on [1,1], but we want it on npix/2,npix/2
sum(psf) # should be == 1  !
imview(psf) #view psf from the top
plot(collect(1:npix), psf[div(npix,2),:]); #plot a slice

# maximum(psf) -> gives us the maximum

# OTF
otf = circshift(fft(psf), (npix/2,npix/2)); #fft result always need to be shifted
mtf = abs.(otf);
imsurf(mtf) #3d view of the mtf
