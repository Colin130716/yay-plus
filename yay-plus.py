import wx
import os


class Mywin(wx.Frame):
   def __init__(self, parent, title):
      super(Mywin, self).__init__(parent, title = title, size = (1000,570)) 
      self.InitUI()
		
   def InitUI(self):   
      self.Show(True)
      self.statusbar = self.CreateStatusBar(1)
      self.statusbar.SetStatusText('Ready')

      self.radioBox = wx.RadioBox(self, -1, "", choices=["安装AUR包", "升级程序", "退出"], majorDimension=0, style=wx.RA_SPECIFY_ROWS)
      self.radioBox.SetSelection(0)
      self.radioBox.Bind(wx.EVT_RADIOBOX, self.OnRadioBox)
      self.sizer = wx.BoxSizer(wx.VERTICAL)
      self.sizer.Add(self.radioBox, 0, wx.EXPAND)
      self.SetSizer(self.sizer)
      self.Centre() 
      self.Show(True)

   def OnRadioBox(self, event):
      selection = event.GetSelection()
      if selection == 0:
         self.statusbar.SetStatusText('正在安装依赖...')
         self.SetStatusText("请查看终端，输入sudo密码")

         os.system("sudo mkdir /tmp/yay-plus")
         os.system("sudo chmod 777 /tmp/yay-plus")
         os.system("cd /tmp/yay-plus")
         os.system("sudo wget https://fastgit.cc/https://github.com/Colin130716/yay-plus/raw/master/install_depend.sh -O /tmp/yay-plus/install_depend.sh")
         os.system("sudo bash /tmp/yay-plus/install_depend.sh")
      elif selection == 1:
         os.system("")
      elif selection == 2:
         print("退出")
         self.Close()

app = wx.App()
Mywin(None, 'yay+')
app.MainLoop()
