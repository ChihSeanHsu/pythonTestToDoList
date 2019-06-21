from django.shortcuts import render
from django.views.generic import TemplateView

# Create your views here.
class HomePage(TemplateView):
    template_name = 'home.html'

    def get(self, request, *args, **kwargs):
        return render(request, self.template_name, {})

    def post(self, request, *args, **kwargs):
        if 'to_do' not in request.session:
            request.session['to_do'] = []
        new_item = request.POST.get('new_item')
        to_do_list = request.session['to_do']
        to_do_list.append(new_item)
        request.session['to_do'] = to_do_list

        return render(request, self.template_name, { 'to_do_list': to_do_list })
