import brl.blitz
import brl.max2d
import brl.glgraphics
import brl.retro
import "renderbuffer.bmx"
TGLPackedTexture^Object{
MinPackingSize%&=mem("_bb_TGLPackedTexture_MinPackingSize")
._filled%&
._u0#&
._v0#&
._u1#&
._v1#&
._x%&
._y%&
._width%&
._height%&
._pwidth%&
._pheight%&
._owner:TGLTexturePack&
._p_right:TGLPackedTexture&
._p_bottom:TGLPackedTexture&
-New%()="_bb_TGLPackedTexture_New"
-Delete%()="_bb_TGLPackedTexture_Delete"
-GetUnused:TGLPackedTexture(width%,height%)="_bb_TGLPackedTexture_GetUnused"
-Buffer%(pixmap:TPixmap)="_bb_TGLPackedTexture_Buffer"
-Name%()="_bb_TGLPackedTexture_Name"
-Unload%()="_bb_TGLPackedTexture_Unload"
-MergeEmpty%()="_bb_TGLPackedTexture_MergeEmpty"
}="bb_TGLPackedTexture"
TGLTexturePack^Object{
._gseq%&
._name%&
._root:TGLPackedTexture&
._width%&
._height%&
._flags%&
._wscale#&
._hscale#&
-New%()="_bb_TGLTexturePack_New"
-Delete%()="_bb_TGLTexturePack_Delete"
-Name%()="_bb_TGLTexturePack_Name"
-Bind%()="_bb_TGLTexturePack_Bind"
-Reset%()="_bb_TGLTexturePack_Reset"
-Init:TGLTexturePack(width%,height%,flags%)="_bb_TGLTexturePack_Init"
-GetUnused:TGLPackedTexture(width%,height%)="_bb_TGLTexturePack_GetUnused"
-MergeEmpty%()="_bb_TGLTexturePack_MergeEmpty"
}="bb_TGLTexturePack"
TGLBufferedImageFrame^TImageFrame{
._gseq%&
._texture:TGLPackedTexture&
.uv#&[]&
-New%()="_bb_TGLBufferedImageFrame_New"
-Delete%()="_bb_TGLBufferedImageFrame_Delete"
-Init:TGLBufferedImageFrame(buffer:TGLPackedTexture)="_bb_TGLBufferedImageFrame_Init"
-Draw%(x0#,y0#,x1#,y1#,tx#,ty#,sx#,sy#,sw#,sh#)="_bb_TGLBufferedImageFrame_Draw"
}="bb_TGLBufferedImageFrame"
TBufferedGLMax2DDriver^TMax2DDriver{
MinimumTextureWidth%&=mem("_bb_TBufferedGLMax2DDriver_MinimumTextureWidth")
MinimumTextureHeight%&=mem("_bb_TBufferedGLMax2DDriver_MinimumTextureHeight")
__blend_funcs%&[]&=mem:p("_bb_TBufferedGLMax2DDriver___blend_funcs")
._buffer:TRenderBuffer&
._cr@&
._cg@&
._cb@&
._ca@&
._txx#&
._txy#&
._tyx#&
._tyy#&
._view_x%&
._view_y%&
._view_w%&
._view_h%&
._texPackages:TGLTexturePack&[]&
._numPackages%&
._blend%&
._clr_r%&
._clr_g%&
._clr_b%&
._poly_xy#&[]&
._poly_colors@&[]&
._r_width#&
._r_height#&
-New%()="_bb_TBufferedGLMax2DDriver_New"
-Delete%()="_bb_TBufferedGLMax2DDriver_Delete"
-Reset%()="_bb_TBufferedGLMax2DDriver_Reset"
-_rectPoints#&[](x0#,y0#,x1#,y1#,tx#,ty#)="_bb_TBufferedGLMax2DDriver__rectPoints"
-GraphicsModes:TGraphicsMode&[]()="_bb_TBufferedGLMax2DDriver_GraphicsModes"
-AttachGraphics:TGraphics(widget%,flags%)="_bb_TBufferedGLMax2DDriver_AttachGraphics"
-CreateGraphics:TGraphics(width%,height%,depth%,hertz%,flags%)="_bb_TBufferedGLMax2DDriver_CreateGraphics"
-SetGraphics%(g:TGraphics)="_bb_TBufferedGLMax2DDriver_SetGraphics"
-Flip%(sync%)="_bb_TBufferedGLMax2DDriver_Flip"
-CreateFrameFromPixmap:TImageFrame(pixmap:TPixmap,flags%)="_bb_TBufferedGLMax2DDriver_CreateFrameFromPixmap"
-SetBlend%(blend%)="_bb_TBufferedGLMax2DDriver_SetBlend"
-SetAlpha%(alpha#)="_bb_TBufferedGLMax2DDriver_SetAlpha"
-SetColor%(r%,g%,b%)="_bb_TBufferedGLMax2DDriver_SetColor"
-SetClsColor%(r%,g%,b%)="_bb_TBufferedGLMax2DDriver_SetClsColor"
-SetViewport%(x%,y%,w%,h%)="_bb_TBufferedGLMax2DDriver_SetViewport"
-SetTransform%(xx#,xy#,yx#,yy#)="_bb_TBufferedGLMax2DDriver_SetTransform"
-SetLineWidth%(width#)="_bb_TBufferedGLMax2DDriver_SetLineWidth"
-Cls%()="_bb_TBufferedGLMax2DDriver_Cls"
-Plot%(x#,y#)="_bb_TBufferedGLMax2DDriver_Plot"
-DrawLine%(x0#,y0#,x1#,y1#,tx#,ty#)="_bb_TBufferedGLMax2DDriver_DrawLine"
-DrawRect%(x0#,y0#,x1#,y1#,tx#,ty#)="_bb_TBufferedGLMax2DDriver_DrawRect"
-DrawOval%(x0#,y0#,x1#,y1#,tx#,ty#)="_bb_TBufferedGLMax2DDriver_DrawOval"
-DrawPoly%(xy#&[],handlex#,handley#,originx#,originy#)="_bb_TBufferedGLMax2DDriver_DrawPoly"
-DrawPixmap%(pixmap:TPixmap,x%,y%)="_bb_TBufferedGLMax2DDriver_DrawPixmap"
-GrabPixmap:TPixmap(x%,y%,width%,height%)="_bb_TBufferedGLMax2DDriver_GrabPixmap"
-SetResolution%(width#,height#)="_bb_TBufferedGLMax2DDriver_SetResolution"
-ToString$()="_bb_TBufferedGLMax2DDriver_ToString"
-RenderBuffer:TRenderBuffer()="_bb_TBufferedGLMax2DDriver_RenderBuffer"
}="bb_TBufferedGLMax2DDriver"
BufferedGLMax2DDriver:TBufferedGLMax2DDriver()="bb_BufferedGLMax2DDriver"